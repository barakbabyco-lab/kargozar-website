<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceResource;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ServiceController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $activeCategoryIds = ServiceCategory::activeHierarchyIds();

        $query = Service::query()
            ->with('category')
            ->where('is_active', true)
            ->whereIn('category_id', $activeCategoryIds);

        if ($request->filled('category')) {
            $selectedCategory = ServiceCategory::query()
                ->where('slug', $request->string('category')->toString())
                ->whereIn('id', $activeCategoryIds)
                ->firstOrFail();

            // Selecting a parent category includes services assigned to any
            // active descendant, not only services assigned to the parent.
            $categoryIds = [(int) $selectedCategory->id];
            $frontier = $categoryIds;

            while ($frontier !== []) {
                $children = ServiceCategory::query()
                    ->whereIn('parent_id', $frontier)
                    ->whereIn('id', $activeCategoryIds)
                    ->pluck('id')
                    ->map(fn ($id): int => (int) $id)
                    ->all();

                $frontier = array_values(array_diff($children, $categoryIds));
                $categoryIds = array_merge($categoryIds, $frontier);
            }

            $query->whereIn('category_id', $categoryIds);
        }

        if ($request->filled('q')) {
            $term = '%'.str_replace(['%', '_'], ['\%', '\_'], $request->string('q')->toString()).'%';
            $query->where(function ($builder) use ($term) {
                $builder->where('title', 'like', $term)
                    ->orWhere('description', 'like', $term);
            });
        }

        return ServiceResource::collection(
            $query->orderBy('sort_order')->orderBy('title')->paginate(20)->withQueryString(),
        );
    }

    public function show(string $slug): ServiceResource
    {
        $service = Service::query()
            ->with('category')
            ->where('slug', $slug)
            ->where('is_active', true)
            ->whereIn('category_id', ServiceCategory::activeHierarchyIds())
            ->firstOrFail();

        return new ServiceResource($service);
    }
}
