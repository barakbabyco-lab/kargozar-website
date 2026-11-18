<?php

namespace App\\Http\\Controllers\\Api\\V1;

use App\\Http\\Controllers\\Controller;
use App\\Http\\Resources\\ServiceResource;
use App\\Models\\Service;
use App\\Models\\ServiceCategory;
use Illuminate\\Http\\Request;
use Illuminate\\Http\\Resources\\Json\\AnonymousResourceCollection;

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
            $query->whereHas('category', fn ($category) => $category
                ->where('slug', $request->string('category')->toString()));
        }

        if ($request->filled('q')) {
            $term = '%'.str_replace(['%', '_'], ['\\%', '\\_'], $request->string('q')->toString()).'%';
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
