import axios from 'axios';

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
  totalPriceInSkill?: string;
}

const client = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://localhost:3000',
});

export default {
  async execute(method: HttpMethod, resource: string, data?: any, params?: any): Promise<ApiResponse<any>> {
    const accessToken = process.env.VUE_APP_API_KEY;
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
};
