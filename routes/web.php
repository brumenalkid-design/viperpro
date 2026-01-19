<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Config;

// O bloco "SYSTEM ONLINE" foi removido daqui para permitir o carregamento das rotas reais.

// CARREGA AS ROTAS DO SISTEMA
if (file_exists(__DIR__ . '/groups/layouts/app.php')) {
    include_once(__DIR__ . '/groups/layouts/app.php');
}