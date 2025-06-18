#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>

#define ARRAY_SIZE 1000000
#define MAX_THREADS 16

// Структура для передачи данных в поток
typedef struct {
    int* array;
    int start;
    int end;
    long long partial_sum;
} ThreadData;

// Функция для вычисления части суммы в потоке
void* compute_partial_sum(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    data->partial_sum = 0;
    
    for (int i = data->start; i < data->end; i++) {
        data->partial_sum += data->array[i];
    }
    
    return NULL;
}

// Последовательное вычисление суммы
long long sequential_sum(int* array, int size) {
    long long sum = 0;
    for (int i = 0; i < size; i++) {
        sum += array[i];
    }
    return sum;
}

// Параллельное вычисление суммы
long long parallel_sum(int* array, int size, int num_threads) {
    pthread_t threads[MAX_THREADS];
    ThreadData thread_data[MAX_THREADS];
    long long total_sum = 0;
    int chunk_size = size / num_threads;
    
    // Создание потоков
    for (int i = 0; i < num_threads; i++) {
        thread_data[i].array = array;
        thread_data[i].start = i * chunk_size;
        thread_data[i].end = (i == num_threads - 1) ? size : (i + 1) * chunk_size;
        
        pthread_create(&threads[i], NULL, compute_partial_sum, &thread_data[i]);
    }
    
    // Ожидание завершения потоков и суммирование результатов
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
        total_sum += thread_data[i].partial_sum;
    }
    
    return total_sum;
}

int main() {
    int* array = malloc(ARRAY_SIZE * sizeof(int));
    if (array == NULL) {
        fprintf(stderr, "Ошибка выделения памяти\n");
        return 1;
    }
    
    // Инициализация массива случайными числами
    srand(time(NULL));
    for (int i = 0; i < ARRAY_SIZE; i++) {
        array[i] = rand() % 100;
    }
    
    // Последовательное вычисление
    clock_t start = clock();
    long long seq_sum = sequential_sum(array, ARRAY_SIZE);
    clock_t end = clock();
    double seq_time = (double)(end - start) / CLOCKS_PER_SEC;
    
    printf("Последовательная сумма: %lld, время: %.6f сек.\n", seq_sum, seq_time);
    
    // Параллельное вычисление с разным количеством потоков
    int thread_counts[] = {2, 4, 8, 16};
    int num_tests = sizeof(thread_counts) / sizeof(thread_counts[0]);
    
    for (int i = 0; i < num_tests; i++) {
        int num_threads = thread_counts[i];
        
        start = clock();
        long long par_sum = parallel_sum(array, ARRAY_SIZE, num_threads);
        end = clock();
        double par_time = (double)(end - start) / CLOCKS_PER_SEC;
        
        printf("Параллельная сумма (%d потоков): %lld, время: %.6f сек., ускорение: %.2fx\n",
               num_threads, par_sum, par_time, seq_time / par_time);
    }
    
    free(array);
    return 0;
}
