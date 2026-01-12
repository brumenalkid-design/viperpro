<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Artisan;

// FORCE GLOBAL CONFIGURATION (HARDCODED)
Config::set('app.key', 'base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=');
Config::set('app.cipher', 'AES-256-CBC');
Config::set('jwt.secret', 'OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=');

Route::get('/', function () {
    try {
        return "<h1>SYSTEM ONLINE</h1><p>Configurations forced successfully.</p>";
    } catch (\Exception $e) {
        return $e->getMessage();
    }
});

// LOAD ORIGINAL ROUTES
if (file_exists(__DIR__ . '/groups/layouts/app.php')) {
    include_once(__DIR__ . '/groups/layouts/app.php');
}


