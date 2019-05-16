import { Injectable } from '@angular/core';
import { Http, Response } from '@angular/http';
import { ReplaySubject } from 'rxjs';
// import 'rxjs/add/operator/map';

/*
  Generated class for the ConfigProvider provider.

  See https://angular.io/docs/ts/latest/guide/dependency-injection.html
  for more info on providers and Angular 2 DI.
*/
@Injectable()
export class ConfigProvider {

  private config = {
    restServer: null, 
    insurer: null
  };

  public ready: ReplaySubject<boolean> = new  ReplaySubject(1);

  constructor(public http: Http) {
    this.loadConfig()
    .then((config) => {
      throw new Error();
      // this.config = config;
      // this.ready.next(true);
    })
    .catch((err) => {
      console.log('ERROR GETTING CONFIG USING DEFAULT', err.message);
      this.config = {
        "restServer": "/api",
        "insurer": "/api"
      }    
      this.ready.next(true);  
    })
  }

  getConfig() {
    if(localStorage.getItem('config')){
      return JSON.parse(localStorage.getItem('config'));
    }

    return this.config;
  }

  setConfig(newConfig) {
    localStorage.setItem('config', JSON.stringify(newConfig));
  }

  resetConfig() {
    localStorage.removeItem('config');
  }

  loadConfig(): Promise<any> {
    // Load the config data.
    return this.http.get('/assets/config.json')
    .map((res: Response) => res.json())
    .toPromise();
  }

}