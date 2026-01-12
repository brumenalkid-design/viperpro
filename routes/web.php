<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Config;

// FORCE JWT SECRET IN MEMORY TO KILL THE "SECRET NOT DEFINED" ERROR
Config::set('jwt.secret', 'OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=');
Config::set('app.cipher', 'AES-256-CBC');

Route::get('/', function () {
    return "<h1>SYSTEM ONLINE</h1><p>Environment keys forced. Database deployment in progress.</p>";
});

// ORIGINAL ROUTES
include_once(__DIR__ . '/groups/layouts/app.php');

