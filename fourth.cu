#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include <math.h>

#define ROWS 500
#define COLS 200
#define MAX_THREADS 16

typedef struct {
    double** arr1;
    double** arr2;
    double** result;
    int start_row;
    int end_row;
    int operation; // 1 - сложение, 2 - вычитание, 3 - умножение, 4 - деление
} ThreadData;

// Создание двумерного массива
double** create_2d_array(int rows, int cols) {
    double** arr = (double**)malloc(rows * sizeof(double*));
    for (int i = 0; i < rows; i++) {
        arr[i] = (double*)malloc(cols * sizeof(double));
    }
    return arr;
}

// Освобождение памяти двумерного массива
void free_2d_array(double** arr, int rows) {
    for (int i = 0; i < rows; i++) {
        free(arr[i]);
    }
    free(arr);
}

// Инициализация массива случайными значениями
void init_array(double** arr, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            arr[i][j] = (double)rand() / RAND_MAX * 100.0 + 1.0; // От 1.0 до 101.0
        }
    }
}

// Последовательные операции
void sequential_operations(double** arr1, double** arr2, double** result, 
                          int rows, int cols, int operation) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            switch (operation) {
                case 1: result[i][j] = arr1[i][j] + arr2[i][j]; break;
                case 2: result[i][j] = arr1[i][j] - arr2[i][j]; break;
                case 3: result[i][j] = arr1[i][j] * arr2[i][j]; break;
                case 4: result[i][j] = arr1[i][j] / arr2[i][j]; break;
            }
        }
    }
}

// Функция потока для параллельных операций
void* parallel_operation(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    for (int i = data->start_row; i < data->end_row; i++) {
        for (int j = 0; j < COLS; j++) {
            switch (data->operation) {
                case 1: data->result[i][j] = data->arr1[i][j] + data->arr2[i][j]; break;
                case 2: data->result[i][j] = data->arr1[i][j] - data->arr2[i][j]; break;
                case 3: data->result[i][j] = data->arr1[i][j] * data->arr2[i][j]; break;
                case 4: data->result[i][j] = data->arr1[i][j] / data->arr2[i][j]; break;
            }
        }
    }
    return NULL;
}

// Параллельные операции
void parallel_operations(double** arr1, double** arr2, double** result, 
                        int rows, int cols, int operation, int num_threads) {
    pthread_t threads[MAX_THREADS];
    ThreadData thread_data[MAX_THREADS];
    int chunk_size = rows / num_threads;

    for (int i = 0; i < num_threads; i++) {
        thread_data[i].arr1 = arr1;
        thread_data[i].arr2 = arr2;
        thread_data[i].result = result;
        thread_data[i].start_row = i * chunk_size;
        thread_data[i].end_row = (i == num_threads - 1) ? rows : (i + 1) * chunk_size;
        thread_data[i].operation = operation;

        pthread_create(&threads[i], NULL, parallel_operation, &thread_data[i]);
    }

    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }
}

// Проверка результатов
int verify_results(double** seq_result, double** par_result, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (fabs(seq_result[i][j] - par_result[i][j]) > 1e-9) {
                printf("Ошибка проверки на [%d][%d]: %.6f != %.6f\n", 
                      i, j, seq_result[i][j], par_result[i][j]);
                return 0;
            }
        }
    }
    return 1;
}

void test_operations(int rows, int cols, int num_threads) {
    double** arr1 = create_2d_array(rows, cols);
    double** arr2 = create_2d_array(rows, cols);
    double** seq_result = create_2d_array(rows, cols);
    double** par_result = create_2d_array(rows, cols);

    // Инициализация массивов
    srand(time(NULL));
    init_array(arr1, rows, cols);
    init_array(arr2, rows, cols);

    const char* operations[] = {"сложение", "вычитание", "умножение", "деление"};
    
    printf("\nТестирование для массива %dx%d (%d потоков):\n", rows, cols, num_threads);
    
    for (int op = 1; op <= 4; op++) {
        // Последовательная версия
        clock_t start = clock();
        sequential_operations(arr1, arr2, seq_result, rows, cols, op);
        double seq_time = (double)(clock() - start) / CLOCKS_PER_SEC;
        
        // Параллельная версия
        start = clock();
        parallel_operations(arr1, arr2, par_result, rows, cols, op, num_threads);
        double par_time = (double)(clock() - start) / CLOCKS_PER_SEC;
        
        // Проверка результатов
        int verified = verify_results(seq_result, par_result, rows, cols);
        
        printf("%10s: seq=%.6f сек, par=%.6f сек, ускорение=%.2fx, %s\n",
               operations[op-1], seq_time, par_time, seq_time/par_time,
               verified ? "верно" : "ошибка");
    }

    free_2d_array(arr1, rows);
    free_2d_array(arr2, rows);
    free_2d_array(seq_result, rows);
    free_2d_array(par_result, rows);
}

int main() {
    int sizes[][2] = {{500, 200}, {1000, 100}, {1000, 200}}; // Всего 100000, 100000, 200000 элементов
    int num_tests = sizeof(sizes) / sizeof(sizes[0]);
    
    int thread_counts[] = {2, 4, 8, 16};
    int num_thread_counts = sizeof(thread_counts) / sizeof(thread_counts[0]);

    for (int i = 0; i < num_tests; i++) {
        for (int j = 0; j < num_thread_counts; j++) {
            test_operations(sizes[i][0], sizes[i][1], thread_counts[j]);
        }
    }

    return 0;
}
