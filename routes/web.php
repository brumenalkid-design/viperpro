<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| IMPORTANTE (PRODUÇÃO):
|--------------------------------------------------------------------------
| NÃO force app.key/app.cipher/jwt.secret aqui.
| Isso sobrescreve o ENV correto (Railway) e quebra o Encrypter do Laravel.
| APP_KEY / APP_CIPHER / JWT_SECRET devem vir do ambiente (.env / Railway Variables).
|
| Removido:
| config(['app.key' => ...]);
| config(['app.cipher' => ...]);
| config(['jwt.secret' => ...]);
|
*/

// CARREGA AS ROTAS DO SISTEMA
if (file_exists(__DIR__ . '/groups/layouts/app.php')) {
    include_once(__DIR__ . '/groups/layouts/app.php');
}
