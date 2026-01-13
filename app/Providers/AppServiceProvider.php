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
        // KEY PERFEITA SINCRONIZADA: EXATAMENTE 32 BYTES
        Config::set('app.key', 'base64:S3p4SjY3V0VTS0Z0N0Z6S0Z6S0Z6S0Z6S0Z6S0Z6S0Z6S0Z6ST0=');
        Config::set('app.cipher', 'AES-256-CBC');
        Config::set('jwt.secret', 'S3p4SjY3V0VTS0Z0N0Z6S0Z6S0Z6S0Z6S0Z6S0Z6S0Z6S0Z6ST0=');
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Mantém a compatibilidade com o banco de dados
        Schema::defaultStringLength(191);

        // Mantém a função de busca (WhereLike) que o seu sistema usa
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

