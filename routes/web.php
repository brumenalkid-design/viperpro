<?php

use App\Models\Game;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| INSTALADOR AUTOMÁTICO (TEMPORÁRIO)
|--------------------------------------------------------------------------
*/
Route::get('/', function () {
    try {
        $sqlPath = base_path('sql/viperpro.1.6.1.sql');
        
        if (!file_exists($sqlPath)) {
            return "Erro: O arquivo sql/viperpro.sql nao foi encontrado. Verifique se a pasta se chama 'sql' no seu GitHub.";
        }

        $sql = file_get_contents($sqlPath);
        DB::unprepared($sql);
        
        return "<h1>Banco de dados instalado com sucesso!</h1><p>Agora apague este bloco de instalador do arquivo web.php para liberar o acesso ao site.</p>";
        
    } catch (\Exception $e) {
        // Se der erro de "tabela ja existe", significa que ja instalou, entao podemos seguir.
        if (str_contains($e->getMessage(), 'already exists')) {
            return "O banco de dados ja parece estar instalado. Tente acessar as outras rotas.";
        }
        return "Erro na instalacao: " . $e->getMessage();
    }
});

/*
|--------------------------------------------------------------------------
| Web Routes (SEU CÓDIGO ORIGINAL ABAIXO)
|--------------------------------------------------------------------------
*/

Route::get('/test', function() {
   $wallet = \App\Models\Wallet::find(1);
   $price = 5;
   \App\Helpers\Core::payBonusVip($wallet, $price);
});

Route::get('clear', function() {
    Artisan::call('optimize:clear');
    return back();
});

// GAMES PROVIDER
include_once(__DIR__ . '/groups/provider/venix.php');

// GATEWAYS
include_once(__DIR__ . '/groups/gateways/sharkpay.php');

/// SOCIAL
include_once(__DIR__ . '/groups/auth/social.php');

// APP
include_once(__DIR__ . '/groups/layouts/app.php');


