<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Models\ServiceCategory;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ServiceCategoryController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $categories = ServiceCategory::query()
            ->whereIn('id', ServiceCategory::activeHierarchyIds())
            ->withCount('children')
            ->orderBy('parent_id')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return ServiceCategoryResource::collection($categories);
    }
}
