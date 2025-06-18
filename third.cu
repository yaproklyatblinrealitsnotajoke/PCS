#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include <math.h>

#define ARRAY_SIZE 1000000
#define MAX_THREADS 16

typedef struct {
    double* arr1;
    double* arr2;
    double* result;
    int start;
    int end;
    int operation; // 1 - сложение, 2 - вычитание, 3 - умножение, 4 - деление
} ThreadData;

// Последовательные операции
void sequential_operations(double* arr1, double* arr2, double* result, int size, int operation) {
    for (int i = 0; i < size; i++) {
        switch (operation) {
            case 1: result[i] = arr1[i] + arr2[i]; break;
            case 2: result[i] = arr1[i] - arr2[i]; break;
            case 3: result[i] = arr1[i] * arr2[i]; break;
            case 4: result[i] = arr1[i] / arr2[i]; break;
        }
    }
}

// Функция потока для параллельных операций
void* parallel_operation(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    for (int i = data->start; i < data->end; i++) {
        switch (data->operation) {
            case 1: data->result[i] = data->arr1[i] + data->arr2[i]; break;
            case 2: data->result[i] = data->arr1[i] - data->arr2[i]; break;
            case 3: data->result[i] = data->arr1[i] * data->arr2[i]; break;
            case 4: data->result[i] = data->arr1[i] / data->arr2[i]; break;
        }
    }
    return NULL;
}

// Параллельные операции
void parallel_operations(double* arr1, double* arr2, double* result, int size, 
                        int operation, int num_threads) {
    pthread_t threads[MAX_THREADS];
    ThreadData thread_data[MAX_THREADS];
    int chunk_size = size / num_threads;

    for (int i = 0; i < num_threads; i++) {
        thread_data[i].arr1 = arr1;
        thread_data[i].arr2 = arr2;
        thread_data[i].result = result;
        thread_data[i].start = i * chunk_size;
        thread_data[i].end = (i == num_threads - 1) ? size : (i + 1) * chunk_size;
        thread_data[i].operation = operation;

        pthread_create(&threads[i], NULL, parallel_operation, &thread_data[i]);
    }

    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }
}

// Проверка результатов
int verify_results(double* seq_result, double* par_result, int size) {
    for (int i = 0; i < size; i++) {
        if (fabs(seq_result[i] - par_result[i]) > 1e-9) {
            printf("Ошибка проверки на индексе %d: %.6f != %.6f\n", 
                  i, seq_result[i], par_result[i]);
            return 0;
        }
    }
    return 1;
}

void test_operations(int size, int num_threads) {
    double* arr1 = malloc(size * sizeof(double));
    double* arr2 = malloc(size * sizeof(double));
    double* seq_result = malloc(size * sizeof(double));
    double* par_result = malloc(size * sizeof(double));

    // Инициализация массивов
    srand(time(NULL));
    for (int i = 0; i < size; i++) {
        arr1[i] = (double)rand() / RAND_MAX * 100.0 + 1.0; // От 1.0 до 101.0
        arr2[i] = (double)rand() / RAND_MAX * 100.0 + 1.0; // От 1.0 до 101.0
    }

    const char* operations[] = {"сложение", "вычитание", "умножение", "деление"};
    
    printf("\nТестирование для %d элементов (%d потоков):\n", size, num_threads);
    
    for (int op = 1; op <= 4; op++) {
        // Последовательная версия
        clock_t start = clock();
        sequential_operations(arr1, arr2, seq_result, size, op);
        double seq_time = (double)(clock() - start) / CLOCKS_PER_SEC;
        
        // Параллельная версия
        start = clock();
        parallel_operations(arr1, arr2, par_result, size, op, num_threads);
        double par_time = (double)(clock() - start) / CLOCKS_PER_SEC;
        
        // Проверка результатов
        int verified = verify_results(seq_result, par_result, size);
        
        printf("%10s: seq=%.6f сек, par=%.6f сек, ускорение=%.2fx, %s\n",
               operations[op-1], seq_time, par_time, seq_time/par_time,
               verified ? "верно" : "ошибка");
    }

    free(arr1);
    free(arr2);
    free(seq_result);
    free(par_result);
}

int main() {
    int sizes[] = {100000, 500000, 1000000};
    int num_tests = sizeof(sizes) / sizeof(sizes[0]);
    
    int thread_counts[] = {2, 4, 8, 16};
    int num_thread_counts = sizeof(thread_counts) / sizeof(thread_counts[0]);

    for (int i = 0; i < num_tests; i++) {
        for (int j = 0; j < num_thread_counts; j++) {
            test_operations(sizes[i], thread_counts[j]);
        }
    }

    return 0;
}
