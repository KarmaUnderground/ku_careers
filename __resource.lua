resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX Jobs'

version '0.1'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',

	'locales/en.lua',
	'locales/fr.lua',

	'config.lua',

	'jobs/gas.lua',

	'libs/random_normal.lua',
	'libs/job_transformer.lua',

	'server/main.lua',
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'locales/fr.lua',
	'config.lua',

	'jobs/gas.lua',
	
	'client/main.lua'
}

dependencies {
	'es_extended',
	'esx_identity',
	'esx_jobs'
}
