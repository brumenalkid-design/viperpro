<?php
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return "Servidor Online - Chaves Geradas";
});

include_once(__DIR__ . '/groups/layouts/app.php');


