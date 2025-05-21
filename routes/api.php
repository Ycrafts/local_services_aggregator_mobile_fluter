// Customer Profile Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/customer-profile', [CustomerProfileController::class, 'show']);
    Route::post('/customer-profile', [CustomerProfileController::class, 'store']);
    Route::put('/customer-profile', [CustomerProfileController::class, 'update']);
    Route::delete('/customer-profile', [CustomerProfileController::class, 'destroy']);
}); 