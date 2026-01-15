<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Arr;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        /**
         * CONFIGURAÇÃO DINÂMICA: 
         * O Laravel agora busca a APP_KEY do ambiente (Railway), 
         * garantindo que a criptografia funcione em qualquer servidor.
         */
        Config::set('app.key', env('APP_KEY'));
        Config::set('app.cipher', 'AES-256-CBC');
        Config::set('jwt.secret', env('APP_KEY'));
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Mantém a compatibilidade de comprimento de strings para o MySQL/PostgreSQL
        Schema::defaultStringLength(191);

        /**
         * MACRO WHERE LIKE:
         * Mantém a funcionalidade de busca avançada em relacionamentos
         * que o seu sistema utiliza.
         */
        Builder::macro('whereLike', function ($attributes, string $searchTerm) {
            $this->where(function (Builder $query) use ($attributes, $searchTerm) {
                foreach (Arr::wrap($attributes) as $attribute) {
                    $query->when(
                        str_contains($attribute, '.'),
                        function (Builder $query) use ($attribute, $searchTerm) {
                            $buffer = explode('.', $attribute);
                            $attributeField = array_pop($buffer);
                            $relationPath = implode('.', $buffer);
                            $query->orWhereHas($relationPath, function (Builder $query) use ($attributeField, $searchTerm) {
                                $query->where($attributeField, 'LIKE', "%{$searchTerm}%");
                            });
                        },
                        function (Builder $query) use ($attribute, $searchTerm) {
                            $query->orWhere($attribute, 'LIKE', "%{$searchTerm}%");
                        }
                    );
                }
            });
            return $this;
        });
    }
}

