<?php

use App\Models\Game;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| INSTALADOR AUTOMÁTICO (TESTA OS DOIS ARQUIVOS)
|--------------------------------------------------------------------------
*/
Route::get('/', function () {
    try {
        // Testa os dois nomes que aparecem na sua pasta SQL
        $files = ['sql/viperpro.sql', 'sql/viperpro.1.6.1.sql'];
        $foundFile = null;

        foreach ($files as $file) {
            if (file_exists(base_path($file))) {
                $foundFile = $file;
                break;
            }
        }

        if (!$foundFile) {
            return "<h1>ERRO CRÍTICO</h1><p>Nenhum dos arquivos (.sql) foi encontrado na pasta /sql/. Verifique o nome da pasta no GitHub.</p>";
        }

        $sql = file_get_contents(base_path($foundFile));
        DB::unprepared($sql);
        
        return "<h1>SUCESSO TOTAL!</h1><p>Banco de dados instalado usando o arquivo: <b>$foundFile</b>. <br>Agora apague este bloco de instalador do web.php para o site abrir.</p>";
        
    } catch (\Exception $e) {
        if (str_contains($e->getMessage(), 'already exists')) {
            return "<h1>O BANCO JÁ ESTÁ PRONTO</h1><p>As tabelas já existem. Remova este instalador do web.php para ver o site.</p>";
        }
        return "<h1>ERRO NA INSTALAÇÃO</h1><pre>" . $e->getMessage() . "</pre>";
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


