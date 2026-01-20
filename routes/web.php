<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Config;

// FORÇA A CHAVE ORIGINAL EM TEMPO DE EXECUÇÃO
config(['app.key' => 'base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=']);
config(['app.cipher' => 'AES-256-CBC']);
config(['jwt.secret' => 'OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=']);

// CARREGA AS ROTAS DO SISTEMA
if (file_exists(__DIR__ . '/groups/layouts/app.php')) {
    include_once(__DIR__ . '/groups/layouts/app.php');
}
