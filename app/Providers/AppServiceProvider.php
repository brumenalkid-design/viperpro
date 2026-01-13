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
        // KEY MESTRA DEFINITIVA: 32 BYTES REAIS PARA AES-256-CBC
        Config::set('app.key', 'base64:uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=');
        Config::set('app.cipher', 'AES-256-CBC');
        Config::set('jwt.secret', 'uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=');
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
