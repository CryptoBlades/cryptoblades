const OK_RESPONSE: number = 200;
const TOO_MANY_REQUESTS_RESPONSE: number = 429;

export class APIHandledCall {

  private onSuccessCallBack?: (data: any) => void;
  private on429Callback?: () => void;
  private onFailCallBack?: () => void;
  private alwaysCallBack?: () => void;

  onSuccess(successCallBack: (data: any) => void): this {
    this.onSuccessCallBack = successCallBack;
    return this;
  }

  onTooManyRequests(tooManyRequestsCallBack: () => void): this {
    this.on429Callback = tooManyRequestsCallBack;
    return this;
  }

  onFail(failCallBack: () => void): this {
    this.onFailCallBack = failCallBack;
    return this;
  }

  always(alwaysCallBack: () => void): this {
    this.alwaysCallBack = alwaysCallBack;
    return this;
  }

  async get(url: string) {
    try
    {
      const result = await fetch(url);

      let stop: boolean;
      stop = false;

      if(result.status === TOO_MANY_REQUESTS_RESPONSE && this.on429Callback !== undefined){
        this.on429Callback();
        stop = true;
      }

      if(!stop && result.status !== OK_RESPONSE && this.onFailCallBack !== undefined){
        this.onFailCallBack();
        stop = true;
      }

      if(!stop && this.onSuccessCallBack !== undefined){
        const resultData = await result.json();
        this.onSuccessCallBack(resultData);
      }
    }
    catch(ex){
      console.log(ex);
    }
    finally{
      if(this.alwaysCallBack !== undefined){
        this.alwaysCallBack();
      }
    }
  }
}