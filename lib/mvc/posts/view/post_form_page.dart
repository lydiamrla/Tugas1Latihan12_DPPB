import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/dio_client.dart';
import '../bloc/post_bloc.dart';
import '../data/post_model.dart';

class PostFormPage extends StatefulWidget {
  const PostFormPage({super.key, this.post});

  static const routeName = '/post-form';

  final PostModel? post;

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController authorController;
  late final TextEditingController articleController;

  File? imageFile;
  final ImagePicker picker = ImagePicker();

  bool get isEdit => widget.post != null;

  @override
  void initState() {
    super.initState();
    titleController =
        TextEditingController(text: widget.post?.title ?? '');
    authorController =
        TextEditingController(text: widget.post?.author ?? '');
    articleController =
        TextEditingController(text: widget.post?.article ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    articleController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Widget buildExistingImageWidget(
      DioClient dioClient, String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 200,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey[300],
        child: const Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  void handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (isEdit) {
      context.read<PostBloc>().add(
            PostUpdated(
              id: widget.post!.id,
              title: titleController.text.trim(),
              author: authorController.text.trim(),
              article: articleController.text.trim(),
              imageFile: imageFile,
            ),
          );
    } else {
      context.read<PostBloc>().add(
            PostCreated(
              title: titleController.text.trim(),
              author: authorController.text.trim(),
              article: articleController.text.trim(),
              imageFile: imageFile,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(isEdit ? 'Edit Post' : 'Tambah Post')),
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state.status == PostStatus.success &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop();
          }

          if (state.status == PostStatus.failure &&
              state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PostStatus.loading;
          final dioClient = context.read<DioClient>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Penulis',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Penulis harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: articleController,
                    decoration: const InputDecoration(
                      labelText: 'Artikel',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Artikel harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (imageFile != null ||
                      widget.post?.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : buildExistingImageWidget(
                              dioClient,
                              widget.post!.imageUrl!,
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      imageFile == null &&
                              widget.post?.imageUrl == null
                          ? 'Pilih Gambar'
                          : 'Ganti Gambar',
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Simpan',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
