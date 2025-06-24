import requests, os, logging
from datetime import datetime

from functions import load_metadata, save_metadata, save_file_to_gcs

logging.basicConfig(
    level  = logging.INFO,
    format = "%(asctime)s %(levelname)s %(message)s"
)

os.environ["BUCKET_NAME"] = "bees-storage"
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = ".secrets/gke-service-account.json"

if __name__ == "__main__":
    
    PAGE_NUMBER = 1

    # ------------------------------------------------------------------------------
    # Load metadata for incremental/full load decision
    # ------------------------------------------------------------------------------
    max_id = load_metadata().get("max_id", None)

    # ------------------------------------------------------------------------------
    # INCREMENTAL LOAD
    # ------------------------------------------------------------------------------
    if max_id:
        
        logging.info("Starting incremental load.")
        
        per_page = 50
        url = "https://api.openbrewerydb.org/v1/breweries?sort=id:desc"
        
        while True:
            logging.info(f"Requesting page {PAGE_NUMBER}.")
            
            # ------------------------------------------------------------------------------
            # Fetch breweries from the API
            # ------------------------------------------------------------------------------
            params   = {"page": PAGE_NUMBER, "per_page": per_page}
            response = requests.get(url, params=params)
            response.raise_for_status()
            breweries = response.json()
            
            # ------------------------------------------------------------------------------
            # Filter new breweries by id
            # ------------------------------------------------------------------------------
            breweries = [brewery for brewery in breweries if brewery['id'] > max_id]
            
            logging.info(f"The last processed id is {max_id}.")
            logging.info(f"Found {len(breweries)} new breweries.")
            
            if breweries:
                # ------------------------------------------------------------------------------
                # Save new breweries to GCS
                # ------------------------------------------------------------------------------
                save_file_to_gcs(
                    breweries,
                    f'bronze/data/{datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")}.json'
                )
                # ------------------------------------------------------------------------------
                # Update metadata with new max_id
                # ------------------------------------------------------------------------------
                save_metadata(
                    {
                        "max_id": max(brewery['id'] for brewery in breweries),
                        "timestamp": datetime.now().isoformat()
                    }
                )
                
            else:
                # ------------------------------------------------------------------------------
                # No new breweries found, end the loop
                # ------------------------------------------------------------------------------
                logging.info("No new breweries found. Incremental load complete.")
                break
            
            PAGE_NUMBER += 1
            
    # ------------------------------------------------------------------------------
    # FULL LOAD (run only for the first time)
    # ------------------------------------------------------------------------------
    else:
        
        logging.info("Starting full load.")
        
        max_id_temporary = None
        per_page = 200
        url = "https://api.openbrewerydb.org/v1/breweries?sort=id:asc"
        
        while True:
            
            logging.info(f"Requesting page {PAGE_NUMBER}.")
            
            # ------------------------------------------------------------------------------
            # Fetch breweries from the API
            # ------------------------------------------------------------------------------
            params   = {"page": PAGE_NUMBER, "per_page": per_page}
            response = requests.get(url, params=params)
            response.raise_for_status()
            breweries = response.json()
            
            if not breweries:
                # ------------------------------------------------------------------------------
                # No more breweries found, save metadata and end the loop
                # ------------------------------------------------------------------------------
                save_metadata(
                    {
                        "max_id": max_id_temporary,
                        "timestamp": datetime.now().isoformat()
                    }
                )
                logging.info("Full load complete.")
                break
            
            # ------------------------------------------------------------------------------
            # Save breweries to GCS
            # ------------------------------------------------------------------------------
            save_file_to_gcs(
                breweries,
                f'bronze/data/{datetime.now().strftime("%Y_%m_%d_%H_%M_%S_%f")}.json'
            )
            
            # ------------------------------------------------------------------------------
            # Update max_id_temporary with highest id from current page
            # ------------------------------------------------------------------------------
            max_id_temporary = max(brewery['id'] for brewery in breweries)
            
            PAGE_NUMBER += 1
