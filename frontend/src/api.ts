import axios from 'axios';
import {MerchandiseOrder, Product} from '@/components/smart/MerchandiseList.vue';
import {Country} from '@/components/smart/ShippingInfoModal.vue';
import {ProductDetails} from '@/components/smart/VariantChoiceModal.vue';
import BigNumber from 'bignumber.js';

enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
}

interface ApiResponse<T> {
  code: number;
  result: T;
  paging: {
    limit: number;
    offset: number;
    total: number;
  };
  totalPriceInSkill?: BigNumber;
}

const client = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://localhost:3000',
});

export default {
  async execute(method: HttpMethod, resource: string, data?: any, params?: any): Promise<ApiResponse<any>> {
    const accessToken = process.env.VUE_APP_API_KEY || 'accessToken';
    return client({
      method,
      url: resource,
      data,
      params,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    }).then(req => {
      return req.data;
    });
  },
  getMerchandiseProducts(limit: number, offset: number): Promise<ApiResponse<Product[]>> {
    return this.execute(HttpMethod.GET, '/merchant/products', undefined, {limit, offset});
  },
  getMerchandiseProductVariants(productId: number): Promise<ApiResponse<ProductDetails>> {
    return this.execute(HttpMethod.GET, `/merchant/products/${productId}`);
  },
  getMerchandiseCountries(): Promise<ApiResponse<Country[]>> {
    return this.execute(HttpMethod.GET, '/merchant/countries');
  },
  getShippingRates(merchandiseOrder: any): Promise<ApiResponse<any>> {
    return this.execute(HttpMethod.POST, '/merchant/shipping/rates', merchandiseOrder);
  },
  createMerchandiseOrder(merchandiseOrder: MerchandiseOrder): Promise<ApiResponse<any>> {
    return this.execute(HttpMethod.POST, '/merchant/create_order', merchandiseOrder);
  },
};
