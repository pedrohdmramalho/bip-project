import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/daily_reflection_bloc.dart';
import '../data/datasource/daily_reflection_remote_ds.dart';
import '../data/repositories/daily_reflection_repository.dart';
import '../data/models/mood_selector.dart';

import '/bloc/daily_reflection_state.dart';
import '/bloc/daily_reflection_event.dart';

class DailyReflectionPage extends StatelessWidget {
  const DailyReflectionPage({super.key});

  @override
  Widget build(BuildContext context){
    final repo = DailyReflectionRepository(
      DailyReflectionRemoteDataSource(FirebaseFirestore.instance),
    );

    return BlocProvider<DailyReflectionBloc>(
      create: (_) => DailyReflectionBloc(repo: repo),
      child: const _DailyReflectionView(),
    );

  }
}

class _DailyReflectionView extends StatelessWidget {
  const _DailyReflectionView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DailyReflectionBloc, DailyReflectionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DailyReflectionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reflection saved!')),
          );
          Navigator.of(context).pop();
        }

        if (state.status == DailyReflectionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Error')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Reflection Page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0x33BBA0F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                'What made you smile today?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              ),
              const SizedBox(height: 16),
              MoodSelector(),
              const SizedBox(height: 36),

              // Faz o conteúdo acima ocupar o máximo do espaço
              Expanded(
                child: Container(),
              ),

              // Rodapé fixo: TextField + Button
              BlocBuilder<DailyReflectionBloc, DailyReflectionState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.mood != current.mood ||
                    previous.text != current.text,
                builder: (context, state) {
                  final isLoading = state.status == DailyReflectionStatus.loading;
                  final canSubmit = state.mood != null && state.text.isNotEmpty;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        maxLines: 6,
                        onChanged: (text) {
                          context
                              .read<DailyReflectionBloc>()
                              .add(TextChanged(text));
                        },
                        decoration: InputDecoration(
                          hintText: 'Start typing your thoughts...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8c30e8),
                          ),
                          onPressed: (!canSubmit || isLoading)
                              ? null
                              : () {
                                  context
                                      .read<DailyReflectionBloc>()
                                      .add(SubmitPressed());
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Entry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}