// ESE 587 FPGA #3

// don't forget to add testdata.h to your project
//#include "inputdata.h"

#include <stdio.h>

#include "platform.h"
#include "xil_printf.h"
#include <math.h>
#include "bais.h"
#include "inputx.h"
#include "weight_x.h"
#include "weight_h.h"
#include <time.h>
#include "xtime_l.h"
int L = 512;

float h[512],c_t[512], it[512], f[512];

float o[512], c[512] , f[512];

float sigmoid(float val);
int main()
{
	XTime tStart, tEnd;

   init_platform();


   // This matrix will hold the M output values for each of the C testcases.
   volatile float* bram_x = (float*)XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR;
   volatile float* bram_wx1 = (float*)XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR;
   volatile float* bram_h = (float*)XPAR_AXI_BRAM_CTRL_2_S_AXI_BASEADDR;
   volatile float* bram_wh1 = (float*)XPAR_AXI_BRAM_CTRL_3_S_AXI_BASEADDR;
   volatile float* bram_w0 = (float*)XPAR_AXI_BRAM_CTRL_4_S_AXI_BASEADDR;
   volatile float* bram_wx2 = (float*)XPAR_AXI_BRAM_CTRL_5_S_AXI_BASEADDR;
   volatile float* bram_wh2 = (float*)XPAR_AXI_BRAM_CTRL_6_S_AXI_BASEADDR;
   volatile float* bram_wx3 = (float*)XPAR_AXI_BRAM_CTRL_7_S_AXI_BASEADDR;
   volatile float* bram_wh3 = (float*)XPAR_AXI_BRAM_CTRL_8_S_AXI_BASEADDR;
   volatile float* bram_wx4 = (float*)XPAR_AXI_BRAM_CTRL_9_S_AXI_BASEADDR;
   volatile float* bram_wh4 = (float*)XPAR_AXI_BRAM_CTRL_10_S_AXI_BASEADDR;
   volatile unsigned int* hw = (unsigned int*)XPAR_MAC1_0_S00_AXI_BASEADDR;


   for (int i = 0; i < 512; i++)
   {
      h[i] = 0;
      c[i] = 0;
   }
   printf("START\n\r");
   XTime_GetTime(&tStart);
   for (int l = 0; l < 28; l++)
   {

   ///////////////////////////////////////////////////////////////////////////////
      // load xt and ht-1
      for (int i = 0; i < L; i++)
      {
         bram_h[i] = h[i];
         bram_x[i] = x[l][i];
      }

   //////////////////////////////////////////////////////////////////////////////////
      // load for it
      for (int i = 0; i < L; i++)
      {
         for (int j = 0; j < L; j++)
         {
            bram_wx1[j] = wxi[i][j];
            bram_wh1[j] = whi[i][j];
			      bram_wx2[j] = wxf[i][j];
			      bram_wh2[j] = whf[i][j];
			      bram_wx3[j] = wxo[i][j];
			      bram_wh3[j] = who[i][j];
			      bram_wx4[j] = wxc[i][j];
			      bram_wh4[j] = whc[i][j];
         }


         hw[0] = 1;
         // Wait for done signal
         while ( (hw[1] & 0x1) == 0)
         {
              ;
         }
         // Deassert start signal

         hw[0] = 0;

        it[i] = bram_w0[0] + bram_w0[1] + bi[i];
		    f[i] = bram_w0[2] + bram_w0[3] + bf[i];
		    o[i] = bram_w0[4] + bram_w0[5] + bo[i];
		    c_t[i] = bram_w0[6] + bram_w0[7] + bc[i];
		    c_t[i] = tanh(c_t[i]);
		    o[i] = sigmoid(o[i]);
		    f[i] = sigmoid(f[i]);
        it[i] = sigmoid(it[i]);
      }

   /////////////////////////////////////////////////////////////////////////////////////
		for (int i = 0; i < 512; i++)
		{
			c[i] = f[i]*c[i] + it[i]*c_t[i];
			h[i] = o[i]*tanh(c[i]);
		}
   }
   XTime_GetTime(&tEnd);

    printf("Output took %.2f us.\n", (1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000)));


   xil_printf("EnD\n\r");
   cleanup_platform();
   return 0;
}

float sigmoid(float val)
{
	return ((exp(val))/(exp(val)+1));
}

