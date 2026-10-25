import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/admin_provider.dart';
import '../models/gallery_item_model.dart';
import '../theme/app_theme.dart';

class GalleryManagerView extends StatefulWidget {
  const GalleryManagerView({super.key});

  @override
  State<GalleryManagerView> createState() => _GalleryManagerViewState();
}

class _GalleryManagerViewState extends State<GalleryManagerView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Elderly Care',
    'Clinical Nursing',
    'Physiotherapy',
    'Staff Training',
    'Medical Equipment',
    'Child & Baby Care',
    'Hidden',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allItems = provider.galleryItems;

    final filtered = allItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.titleSi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Hidden') return !item.isPublished;
      return item.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final publishedCount = allItems.where((g) => g.isPublished).length;

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================= HEADER =======================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Photo Gallery & Web Showcase',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.emerald200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done_rounded, size: 12, color: AppTheme.emerald800),
                                SizedBox(width: 4),
                                Text(
                                  'Live Web Sync',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.emerald800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload real patient care, nursing, and staff photos (PNG, JPG) to showcase your clinical excellence on the website.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (allItems.isEmpty)
                      OutlinedButton.icon(
                        onPressed: () async {
                          await provider.seedDefaultGallery();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Default healthcare gallery photos seeded!'),
                                backgroundColor: AppTheme.emeraldGreen,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Seed Sample Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openGalleryItemDialog(context, null),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text('Upload / Add Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ======================= STATS STRIP =======================
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Photos',
                  value: '${allItems.length}',
                  subtitle: 'Uploaded in Gallery',
                  icon: Icons.collections_rounded,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Live on Website',
                  value: '$publishedCount',
                  subtitle: 'Visible to Public',
                  icon: Icons.visibility_rounded,
                  color: AppTheme.emeraldGreen,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Hidden Photos',
                  value: '${allItems.length - publishedCount}',
                  subtitle: 'Drafts / Unpublished',
                  icon: Icons.visibility_off_rounded,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  title: 'Supported Formats',
                  value: 'PNG, JPG, WebP',
                  subtitle: 'Optimized Web Media',
                  icon: Icons.image_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ======================= FILTER & SEARCH BAR =======================
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search photos by title, caption, or category...',
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Category chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.slate800,
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.slate900,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ======================= GALLERY GRID =======================
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No photos found',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.slate800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Try adjusting your search query or category filter.'
                          : 'Click "Upload / Add Photo" to showcase your first care image on the website.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (allItems.isEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.seedDefaultGallery(),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Seed Sample Photos'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 750) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 1150) {
                    crossAxisCount = 2;
                  } else if (constraints.maxWidth >= 1500) {
                    crossAxisCount = 4;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 290,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return _buildGalleryCard(item, provider);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
                  Text(subtitle, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(GalleryItemModel item, AdminProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isPublished ? Colors.grey.shade200 : Colors.amber.shade200,
          width: item.isPublished ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Viewport
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: item.imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(item.imageUrl.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Category Badge Top-Left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              // Live Status Badge Top-Right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: item.isPublished ? const Color(0xFF059669) : Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isPublished ? 'Live on Web' : 'Hidden',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Caption & Info Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.slate900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.titleSi.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.titleSi,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  const Divider(height: 1),
                  const SizedBox(height: 4),

                  // Bottom Action Row
                  Row(
                    children: [
                      // Toggle Switch Live
                      InkWell(
                        onTap: () => provider.toggleGalleryItemPublished(item.id, !item.isPublished),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            item.isPublished ? 'Hide from Web' : 'Publish to Web',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.isPublished ? Colors.orange.shade800 : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 15, color: AppTheme.primaryBlue),
                        tooltip: 'Edit Photo',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => _openGalleryItemDialog(context, item),
                      ),
                      const SizedBox(width: 4),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red),
                        tooltip: 'Delete Photo',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => _confirmDeleteGalleryItem(context, item, provider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
      ),
    );
  }

  // ======================= ADD / EDIT GALLERY ITEM DIALOG =======================
  void _openGalleryItemDialog(BuildContext context, GalleryItemModel? existing) {
    final isEditing = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final titleSiCtrl = TextEditingController(text: existing?.titleSi ?? '');
    final urlCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String category = existing?.category ?? 'Elderly Care';
    bool isPublished = existing?.isPublished ?? true;
    String? localPreviewImage = existing?.imageUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Gallery Photo' : 'Upload / Add Photo to Web',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload / Select Image Button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1. Select or Upload Image (PNG, JPG, WebP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final picked = await FilePicker.pickFile(
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                                    );
                                    if (picked != null) {
                                      final bytes = await picked.readAsBytes();
                                      final ext = (picked.extension ?? 'jpg').toLowerCase();
                                      final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
                                      final base64String = base64Encode(bytes);
                                      final dataUrl = 'data:image/$mimeExt;base64,$base64String';

                                      setDialogState(() {
                                        urlCtrl.text = dataUrl;
                                        localPreviewImage = dataUrl;
                                      });
                                    }
                                  } catch (e) {
                                    debugPrint('File picker error: $e');
                                  }
                                },
                                icon: const Icon(Icons.file_upload_rounded, size: 16),
                                label: const Text('Choose File from PC / Mobile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('or paste URL below', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: urlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Image Data / Web URL *',
                              hintText: 'https://example.com/photo.jpg or data:image/...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) => setDialogState(() => localPreviewImage = val.trim()),
                          ),

                          // Image Preview Thumbnail
                          if (localPreviewImage != null && localPreviewImage!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                height: 130,
                                width: double.infinity,
                                child: localPreviewImage!.startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(localPreviewImage!.split(',').last),
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                                      )
                                    : Image.network(
                                        localPreviewImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => _buildPlaceholderImage(),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Title English
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Photo Title (English) *',
                        hintText: 'e.g. Senior Patient Routine Vital Checks',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title Sinhala
                    TextField(
                      controller: titleSiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Photo Title (Sinhala)',
                        hintText: 'e.g. වැඩිහිටි රෝගී දෛනික සෞඛ්‍ය පරීක්ෂාව',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _categories.sublist(1, _categories.length - 1).contains(category) ? category : 'Elderly Care',
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _categories
                          .sublist(1, _categories.length - 1)
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Description Caption
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Short Description / Caption',
                        hintText: 'e.g. Qualified nursing aide performing BP and blood glucose test.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Publish Toggle
                    CheckboxListTile(
                      value: isPublished,
                      onChanged: (val) => setDialogState(() => isPublished = val ?? true),
                      title: const Text('Publish Live to Website Gallery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: const Text('When enabled, this photo appears live on the primelifecare.lk gallery section.', style: TextStyle(fontSize: 10.5)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(isEditing ? 'Save Changes' : 'Upload to Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a Photo Title and select an Image!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final newItem = GalleryItemModel(
                    id: existing?.id ?? 'gal_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    titleSi: titleSiCtrl.text.trim(),
                    imageUrl: urlCtrl.text.trim(),
                    category: category,
                    description: descCtrl.text.trim(),
                    isPublished: isPublished,
                  );

                  final provider = context.read<AdminProvider>();
                  Navigator.pop(ctx);

                  if (isEditing) {
                    await provider.updateGalleryItem(newItem);
                  } else {
                    await provider.addGalleryItem(newItem);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Photo "${newItem.title}" ${isPublished ? "published live to website" : "saved"}!'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ======================= DELETE CONFIRMATION =======================
  void _confirmDeleteGalleryItem(BuildContext context, GalleryItemModel item, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Text('Are you sure you want to permanently remove "${item.title}" from the website gallery?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteGalleryItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Photo "${item.title}" deleted.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Photo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
