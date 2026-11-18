<?php

namespace App\Http\Controllers\Api\V1\Staff;

use App\Http\Controllers\Controller;
use App\Http\Resources\ServiceCategoryResource;
use App\Http\Resources\ServiceResource;
use App\Models\AuditLog;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class StaffCatalogController extends Controller
{
    public function categories()
    {
        return ServiceCategoryResource::collection(
            ServiceCategory::query()
                ->withCount('children')
                ->orderBy('parent_id')
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        );
    }

    public function storeCategory(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'parent_id' => ['nullable', 'integer', 'exists:service_categories,id'],
            'name' => ['required', 'string', 'max:120'],
            'slug' => ['required', 'string', 'max:140', 'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/', 'unique:service_categories,slug'],
            'description' => ['nullable', 'string', 'max:2000'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:100000'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $category = DB::transaction(function () use ($request, $validator) {
            $category = ServiceCategory::create($validator->validated());
            $this->audit($request, 'catalog.category_created', $category, [
                'slug' => $category->slug,
                'parent_id' => $category->parent_id,
            ]);

            return $category;
        });

        return response()->json([
            'data' => (new ServiceCategoryResource($category->loadCount('children')))->resolve(),
        ], 201);
    }

    public function updateCategory(Request $request, int $categoryId): JsonResponse
    {
        $category = ServiceCategory::findOrFail($categoryId);
        $validator = Validator::make($request->all(), [
            'parent_id' => ['sometimes', 'nullable', 'integer', 'exists:service_categories,id'],
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'slug' => ['sometimes', 'required', 'string', 'max:140', 'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/', 'unique:service_categories,slug,'.$category->id],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:100000'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $validator->after(function ($validator) use ($request, $category): void {
            if (! $request->exists('parent_id') || $request->input('parent_id') === null) {
                return;
            }

            $parentId = (int) $request->input('parent_id');
            if ($parentId === (int) $category->id) {
                $validator->errors()->add('parent_id', 'A category cannot be its own parent.');

                return;
            }

            $visited = [];
            $ancestor = ServiceCategory::query()->find($parentId);
            while ($ancestor !== null) {
                if ((int) $ancestor->id === (int) $category->id) {
                    $validator->errors()->add('parent_id', 'A category cannot be moved below one of its descendants.');

                    return;
                }

                if (isset($visited[$ancestor->id])) {
                    $validator->errors()->add('parent_id', 'The selected parent belongs to an invalid category hierarchy.');

                    return;
                }

                $visited[$ancestor->id] = true;
                $ancestor = $ancestor->parent_id === null
                    ? null
                    : ServiceCategory::query()->find($ancestor->parent_id);
            }
        });

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        DB::transaction(function () use ($request, $category, $validator): void {
            $category->update($validator->validated());
            $this->audit($request, 'catalog.category_updated', $category, [
                'fields' => array_keys($validator->validated()),
                'parent_id' => $category->parent_id,
            ]);
        });

        return response()->json([
            'data' => (new ServiceCategoryResource($category->refresh()->loadCount('children')))->resolve(),
        ]);
    }

    public function services(Request $request)
    {
        $query = Service::query()->with('category')->orderBy('sort_order')->orderBy('title');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }

        if ($request->filled('q')) {
            $term = '%'.$request->string('q')->toString().'%';
            $query->where(function ($builder) use ($term) {
                $builder->where('title', 'like', $term)->orWhere('slug', 'like', $term);
            });
        }

        return ServiceResource::collection($query->paginate(30)->withQueryString());
    }

    public function storeService(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'category_id' => ['required', 'integer', 'exists:service_categories,id'],
            'title' => ['required', 'string', 'max:180'],
            'slug' => ['required', 'string', 'max:190', 'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/', 'unique:services,slug'],
            'description' => ['required', 'string', 'max:10000'],
            'requirements' => ['nullable', 'array', 'max:50'],
            'requirements.*' => ['string', 'max:300'],
            'estimated_days' => ['nullable', 'integer', 'min:1', 'max:365'],
            'base_price' => ['nullable', 'numeric', 'min:0', 'max:99999999999'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:100000'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        $service = DB::transaction(function () use ($request, $validator) {
            $service = Service::create($validator->validated());
            $this->audit($request, 'catalog.service_created', $service, ['slug' => $service->slug]);

            return $service;
        });

        return response()->json([
            'data' => (new ServiceResource($service->load('category')))->resolve(),
        ], 201);
    }

    public function updateService(Request $request, int $serviceId): JsonResponse
    {
        $service = Service::findOrFail($serviceId);
        $validator = Validator::make($request->all(), [
            'category_id' => ['sometimes', 'required', 'integer', 'exists:service_categories,id'],
            'title' => ['sometimes', 'required', 'string', 'max:180'],
            'slug' => ['sometimes', 'required', 'string', 'max:190', 'regex:/^[a-z0-9]+(?:-[a-z0-9]+)*$/', 'unique:services,slug,'.$service->id],
            'description' => ['sometimes', 'required', 'string', 'max:10000'],
            'requirements' => ['sometimes', 'nullable', 'array', 'max:50'],
            'requirements.*' => ['string', 'max:300'],
            'estimated_days' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:365'],
            'base_price' => ['sometimes', 'nullable', 'numeric', 'min:0', 'max:99999999999'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:100000'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if ($validator->fails()) {
            return $this->validationError($validator->errors()->toArray());
        }

        DB::transaction(function () use ($request, $service, $validator): void {
            $service->update($validator->validated());
            $this->audit($request, 'catalog.service_updated', $service, ['fields' => array_keys($validator->validated())]);
        });

        return response()->json([
            'data' => (new ServiceResource($service->refresh()->load('category')))->resolve(),
        ]);
    }

    private function audit(Request $request, string $action, Service|ServiceCategory $subject, array $metadata): void
    {
        AuditLog::create([
            'actor_type' => 'staff',
            'actor_id' => $request->user()->getAuthIdentifier(),
            'action' => $action,
            'subject_type' => $subject::class,
            'subject_id' => $subject->getKey(),
            'request_id' => $request->header('X-Request-Id', (string) Str::uuid()),
            'ip_hash' => hash('sha256', (string) $request->ip()),
            'metadata' => $metadata,
        ]);
    }

    private function validationError(array $fields): JsonResponse
    {
        return response()->json([
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'message' => 'اطلاعات ارسالی معتبر نیست.',
                'fields' => $fields,
            ],
        ], 422);
    }
}
