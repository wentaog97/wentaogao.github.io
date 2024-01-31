#include <stdio.h>
#include <time.h>
#include <stdlib.h>

#define MAX_RAND 10

// Device Code, 1 dimensional
__global__ void add(int *a, int *b, int *c) {
	c[blockIdx.x] = a[blockIdx.x] + b[blockIdx.x];
}


// Host Code
// Sequential CPU implementation of vector addition
void vector_add(int* a, int* b, int* result, int n) {
    for (int i = 0; i < n; i++) {
        result[i] = a[i] + b[i];
    }
}

// Generate random numbers from -10 to 10
void random_ints(int* a, int n) {
    for (int i = 0; i < n; ++i)
        a[i] = (rand() % (2 * MAX_RAND + 1)) - MAX_RAND; // Creates Random from -10 to 10
}
//-----------------
void printArray(int* vals, int size) {
    for (int i = 0; i < size; i++) {
        printf("%d ", vals[i]);
    }
    printf("\n");
}
//-----------------

int main(void) {

	// Open a new file for writing
    FILE* deviceToHostTime = fopen("deviceToHostTime.csv", "w");
	FILE* hostToDeviceTime = fopen("hostToDeviceTime.csv", "w");
	FILE* operationTime = fopen("operationTime.csv", "w");

	// Declare variables to hold the start and end times
	clock_t start, end;
	double deviceToHost_time_used, hostToDevice_time_used, mathOperation_time_used;


	for(int N = 32; N<=1073741824; N*=2){
		// Initialize vectors
		int *a, *b, *c;
		int *d_a, *d_b, *d_c;
		int size = N * sizeof(int);

		// Allocate Device memory
		cudaMalloc((void **)&d_a,size);
		cudaMalloc((void **)&d_b,size);
		cudaMalloc((void **)&d_c,size);

		// Allocate Host memory and fill vectors with random ints
		a=(int *)malloc(size); 
		b=(int *)malloc(size); 
		c=(int *)malloc(size);
		random_ints(a,N);
		random_ints(b,N);

		//printf("A = "); printArray(a,N);
		//printf("B = "); printArray(b,N);

		// Execute in Device
		for(int blocksPerGrid = 1; blocksPerGrid<=1024; blocksPerGrid*=2){
			for(int threadsPerBlock = 1; threadsPerBlock<=1024; threadsPerBlock*=2){
				// Host to Device
				start = clock();
				cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice);
				cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice);
				end = clock();
				hostToDevice_time_used = ((double) (end - start))/CLOCKS_PER_SEC;
				fprintf(hostToDeviceTime, "%d, %f\n", N, hostToDevice_time_used);

				// Doing the addition
				start = clock();
				add<<<blocksPerGrid,threadsPerBlock>>>(d_a,d_b,d_c);
				cudaThreadSynchronize();
				end = clock();
				mathOperation_time_used = ((double) (end - start))/CLOCKS_PER_SEC;
				fprintf(operationTime, "%d, %d,%d,%f\n", N, blocksPerGrid, threadsPerBlock, mathOperation_time_used);

				// Get result back from Drvice to Host
				start = clock();
				cudaMemcpy(c, d_c, size, cudaMemcpyDeviceToHost);
				end = clock();
				deviceToHost_time_used = ((double) (end - start))/CLOCKS_PER_SEC;
				fprintf(deviceToHostTime, "%d,%f\n", N, deviceToHost_time_used);
			}
		}
		//printf("C = "); printArray(c,N);

		free(a);
		free(b);
		free(c);
		cudaFree(d_a);
		cudaFree(d_b);
		cudaFree(d_c);
	}

	fclose(deviceToHostTime);
	fclose(hostToDeviceTime);
	fclose(operationTime);
	return 0;
}