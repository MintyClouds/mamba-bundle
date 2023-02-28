
nextcloud-scan-files:
	docker-compose exec nextcloud php occ files:scan --all

nextcloud-scan-preview:
	docker-compose exec nextcloud php occ preview:generate-all

nextcloud-scan-memories:
	docker-compose exec nextcloud php occ memories:index

nextcloud-scan-full: nextcloud-scan-files nextcloud-scan-preview nextcloud-scan-memories

nextcloud-restart:
	docker-compose stop nextcloud && docker-compose rm -f nextcloud && docker-compose up -d nextcloud 

