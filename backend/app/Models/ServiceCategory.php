<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceCategory extends Model
{
    protected $fillable = ['parent_id', 'name', 'slug', 'description', 'is_active', 'sort_order'];

    protected function casts(): array
    {
        return [
            'parent_id' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /**
     * Return category IDs whose complete parent chain is active.
     *
     * Public catalog endpoints use this list so disabling any ancestor
     * consistently hides the entire branch without deleting its records.
     *
     * @return array<int, int>
     */
    public static function activeHierarchyIds(): array
    {
        $categories = static::query()
            ->get(['id', 'parent_id', 'is_active'])
            ->keyBy('id');

        $activeIds = [];

        foreach ($categories as $category) {
            if (! $category->is_active) {
                continue;
            }

            $ancestorId = $category->parent_id;
            $visited = [];
            $valid = true;

            while ($ancestorId !== null) {
                if (isset($visited[$ancestorId]) || ! $categories->has($ancestorId)) {
                    $valid = false;
                    break;
                }

                $visited[$ancestorId] = true;
                $ancestor = $categories->get($ancestorId);

                if (! $ancestor->is_active) {
                    $valid = false;
                    break;
                }

                $ancestorId = $ancestor->parent_id;
            }

            if ($valid) {
                $activeIds[] = (int) $category->id;
            }
        }

        return $activeIds;
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id');
    }

    public function services(): HasMany
    {
        return $this->hasMany(Service::class, 'category_id');
    }
}
