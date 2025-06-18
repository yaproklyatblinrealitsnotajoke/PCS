#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>
#include <stdbool.h>

// Размеры массивов для тестирования
#define SIZE_1 100000
#define SIZE_2 500000
#define SIZE_3 1000000
#define MAX_THREADS 16

// Структура для передачи данных в поток Bitonic Sort
typedef struct {
    int* array;
    int start;
    int end;
    int dir; // 1 - по возрастанию, 0 - по убыванию
} BitonicData;

// Объединение двух отсортированных подмассивов (для Merge Sort)
void merge(int* array, int left, int mid, int right) {
    int n1 = mid - left + 1;
    int n2 = right - mid;

    int* L = malloc(n1 * sizeof(int));
    int* R = malloc(n2 * sizeof(int));

    for (int i = 0; i < n1; i++)
        L[i] = array[left + i];
    for (int j = 0; j < n2; j++)
        R[j] = array[mid + 1 + j];

    int i = 0, j = 0, k = left;
    while (i < n1 && j < n2) {
        if (L[i] <= R[j]) {
            array[k] = L[i];
            i++;
        } else {
            array[k] = R[j];
            j++;
        }
        k++;
    }

    while (i < n1) {
        array[k] = L[i];
        i++;
        k++;
    }

    while (j < n2) {
        array[k] = R[j];
        j++;
        k++;
    }

    free(L);
    free(R);
}

// Последовательная сортировка слиянием
void merge_sort(int* array, int left, int right) {
    if (left < right) {
        int mid = left + (right - left) / 2;
        merge_sort(array, left, mid);
        merge_sort(array, mid + 1, right);
        merge(array, left, mid, right);
    }
}

// Сравнение и обмен элементов для Bitonic Sort
void compare_and_swap(int* a, int* b, int dir) {
    if ((*a > *b && dir) || (*a < *b && !dir)) {
        int temp = *a;
        *a = *b;
        *b = temp;
    }
}

// Последовательная часть Bitonic Sort
void bitonic_merge(int* array, int low, int cnt, int dir) {
    if (cnt > 1) {
        int k = cnt / 2;
        for (int i = low; i < low + k; i++)
            compare_and_swap(&array[i], &array[i + k], dir);
        bitonic_merge(array, low, k, dir);
        bitonic_merge(array, low + k, k, dir);
    }
}

// Параллельная сортировка Bitonic Sort
void* bitonic_sort_thread(void* arg) {
    BitonicData* data = (BitonicData*)arg;
    if (data->end - data->start > 1) {
        int mid = (data->end + data->start) / 2;
        
        // Создаем потоки для каждой половины
        pthread_t thread1, thread2;
        
        BitonicData data1 = {data->array, data->start, mid, !data->dir};
        BitonicData data2 = {data->array, mid, data->end, data->dir};
        
        pthread_create(&thread1, NULL, bitonic_sort_thread, &data1);
        pthread_create(&thread2, NULL, bitonic_sort_thread, &data2);
        
        pthread_join(thread1, NULL);
        pthread_join(thread2, NULL);
        
        // Объединяем результаты
        bitonic_merge(data->array, data->start, data->end - data->start, data->dir);
    }
    return NULL;
}

// Проверка отсортированности массива
bool is_sorted(int* array, int size, int ascending) {
    for (int i = 0; i < size - 1; i++) {
        if (ascending && array[i] > array[i + 1])
            return false;
        if (!ascending && array[i] < array[i + 1])
            return false;
    }
    return true;
}

// Тестирование сортировки для массива заданного размера
void test_sort(int size) {
    int* array_seq = malloc(size * sizeof(int));
    int* array_par = malloc(size * sizeof(int));
    
    // Инициализация массива случайными числами
    srand(time(NULL));
    for (int i = 0; i < size; i++) {
        array_seq[i] = rand() % 10000;
        array_par[i] = array_seq[i];
    }
    
    printf("\nТестирование для массива из %d элементов:\n", size);
    
    // Последовательная сортировка слиянием
    clock_t start = clock();
    merge_sort(array_seq, 0, size - 1);
    clock_t end = clock();
    double seq_time = (double)(end - start) / CLOCKS_PER_SEC;
    printf("Последовательная сортировка слиянием: %.6f сек., %s\n", 
           seq_time, is_sorted(array_seq, size, 1) ? "успешно" : "ошибка");
    
    // Параллельная Bitonic сортировка
    start = clock();
    BitonicData data = {array_par, 0, size, 1}; // Сортировка по возрастанию
    pthread_t main_thread;
    pthread_create(&main_thread, NULL, bitonic_sort_thread, &data);
    pthread_join(main_thread, NULL);
    end = clock();
    double par_time = (double)(end - start) / CLOCKS_PER_SEC;
    printf("Параллельная Bitonic сортировка: %.6f сек., %s, ускорение: %.2fx\n", 
           par_time, is_sorted(array_par, size, 1) ? "успешно" : "ошибка",
           seq_time / par_time);
    
    free(array_seq);
    free(array_par);
}

int main() {
    // Тестируем для трех разных размеров массивов
    test_sort(SIZE_1);
    test_sort(SIZE_2);
    test_sort(SIZE_3);
    
    return 0;
}
