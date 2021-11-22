import axios from 'axios';
import {Country, MerchandiseOrderData, Product} from '@/components/smart/MerchandiseList.vue';

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
}

const client = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://localhost:3000',
});

export default {
  async execute(method: HttpMethod, resource: string, data?: any) {
    const accessToken = process.env.VUE_APP_API_KEY || 'accessToken';
    return client({
      method,
      url: resource,
      data,
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    }).then(req => {
      return req.data;
    });
  },
  getMerchandiseProducts(): Promise<ApiResponse<Product[]>> {
    return this.execute(HttpMethod.GET, '/merchant/products');
  },
  getMerchandiseCountries(): Promise<ApiResponse<Country[]>> {
    return this.execute(HttpMethod.GET, '/merchant/countries');
  },
  createMerchandiseOrder(orderData: MerchandiseOrderData): Promise<ApiResponse<any>> {
    return this.execute(HttpMethod.POST, '/merchant/create_order', orderData);
  },
};
