#include <stdio.h>

int main(void)
{
	int a[10] = { 0 }, i;

	for (i = 0; i < 10; i++)
		printf("%d ", a[i]);
	puts("");

	a[0] =
	a[1] =
	a[3] =
	a[4] =
	a[5] =
	a[6] =
	a[7] = 
		10;
	for (i = 0; i < 10; i++)
		printf("%d ", a[i]);

	puts("");
	return 0;
}
