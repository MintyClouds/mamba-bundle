
nextcloud-scan-files:
	docker-compose exec nextcloud php occ files:scan --all

nextcloud-scan-preview-full:
	docker-compose exec nextcloud php occ preview:generate-all

nextcloud-scan-preview-periodic:
	docker-compose exec nextcloud php occ preview:pre-generate

nextcloud-scan-memories:
	docker-compose exec nextcloud php occ memories:index

nextcloud-scan-full: nextcloud-scan-files nextcloud-scan-preview-full nextcloud-scan-memories

nextcloud-scan-periodic: nextcloud-scan-files nextcloud-scan-preview-periodic nextcloud-scan-memories

nextcloud-restart:
	docker-compose stop nextcloud && docker-compose rm -f nextcloud && docker-compose up -d nextcloud 

