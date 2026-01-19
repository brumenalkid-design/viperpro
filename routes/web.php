<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Config;

Route::get('/', function () {
    return "<h1>SYSTEM ONLINE</h1><p>The core application is now operational.</p>";
});

// CARREGA AS ROTAS DO SISTEMA
if (file_exists(__DIR__ . '/groups/layouts/app.php')) {
    include_once(__DIR__ . '/groups/layouts/app.php');
}


