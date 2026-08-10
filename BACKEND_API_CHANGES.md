# Backend API Changes Required

## Disease Counts Endpoint - Yearly Filtering Support

### Current Implementation
```php
Route::get('/user/disease-counts', [ScanResultController::class, 'myDiseaseCounts'])
    ->name('myDiseaseCounts');
```

### Required Changes

#### 1. Update Service Method `getUserDiseaseCounts`

**Location:** `app/Services/ScanService.php` (or equivalent)

**Current Code:**
```php
public function getUserDiseaseCounts(int $userId)
{
    $counts = ScanResult::where('user_id', $userId)
        ->select(
            'disease_key',
            DB::raw('COUNT(*) as total')
        )
        ->groupBy('disease_key')
        ->pluck('total', 'disease_key');

    return [
        'healthy' => $counts['healthy'] ?? 0,
        'black_pod_disease' => $counts['black_pod_disease'] ?? 0,
        'cacao_pod_borer' => $counts['cacao_pod_borer'] ?? 0,
        'mealybug' => $counts['mealybug'] ?? 0,
    ];
}
```

**Updated Code:**
```php
public function getUserDiseaseCounts(int $userId, ?int $year = null)
{
    $query = ScanResult::where('user_id', $userId);

    // Apply year filter if provided
    if ($year !== null) {
        $query->whereYear('scanned_at', $year);
    }

    $counts = $query
        ->select(
            'disease_key',
            DB::raw('COUNT(*) as total')
        )
        ->groupBy('disease_key')
        ->pluck('total', 'disease_key');

    return [
        'healthy' => $counts['healthy'] ?? 0,
        'black_pod_disease' => $counts['black_pod_disease'] ?? 0,
        'cacao_pod_borer' => $counts['cacao_pod_borer'] ?? 0,
        'mealybug' => $counts['mealybug'] ?? 0,
    ];
}
```

#### 2. Update Controller Method `myDiseaseCounts`

**Location:** `app/Http/Controllers/ScanResultController.php` (or equivalent)

**Current Code:**
```php
public function myDiseaseCounts(Request $request)
{
    $userId = $request->user()->id;
    $diseaseCounts = $this->scanService->getUserDiseaseCounts($userId);

    return response()->json([
        'status' => 'OK',
        'data' => $diseaseCounts
    ], 200);
}
```

**Updated Code:**
```php
public function myDiseaseCounts(Request $request)
{
    // Validate optional year parameter
    $validated = $request->validate([
        'year' => 'nullable|integer|min:2000|max:' . (date('Y') + 1),
    ]);

    $userId = $request->user()->id;
    $year = $validated['year'] ?? null;

    $diseaseCounts = $this->scanService->getUserDiseaseCounts($userId, $year);

    return response()->json([
        'status' => 'OK',
        'data' => $diseaseCounts
    ], 200);
}
```

### API Usage Examples

#### Get All-Time Counts
```http
GET /api/theobrotect/scans/user/disease-counts
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "OK",
  "data": {
    "healthy": 45,
    "black_pod_disease": 12,
    "cacao_pod_borer": 8,
    "mealybug": 5
  }
}
```

#### Get Counts for Specific Year
```http
GET /api/theobrotect/scans/user/disease-counts?year=2026
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "OK",
  "data": {
    "healthy": 10,
    "black_pod_disease": 4,
    "cacao_pod_borer": 2,
    "mealybug": 3
  }
}
```

### Important Notes

1. **Authentication:** The endpoint uses `auth:sanctum` middleware. User ID is obtained from `$request->user()->id`, never from client input.

2. **Date Field:** The filter uses the `scanned_at` field. Ensure this field exists and is properly populated in the `scan_results` table.

3. **Validation:** Year parameter is optional, must be an integer between 2000 and next year if provided.

4. **Backward Compatibility:** If no year is provided, the endpoint returns all-time counts (existing behavior preserved).

5. **Performance:** For users with many scans, consider adding an index on `(user_id, scanned_at)` in the `scan_results` table:
   ```sql
   CREATE INDEX idx_scan_results_user_year ON scan_results(user_id, scanned_at);
   ```

### Testing Checklist

- [ ] Endpoint returns all-time counts when no year parameter is provided
- [ ] Endpoint returns filtered counts when valid year is provided
- [ ] Invalid year values return validation error
- [ ] Authentication is required (401 for unauthenticated requests)
- [ ] User can only see their own scan counts
- [ ] Response structure matches expected format
- [ ] Zero counts are properly returned when no scans exist for the period
