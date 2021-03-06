/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
import { authHandlerFactory, FabricProxy, IFabricConfig, setupMiddleware } from 'common';
import * as express from 'express';
import * as expressLess from 'express-less';
import * as path from 'path';
import { Router } from './router/router';

export async function setup(config: IFabricConfig) {
    const app = express();

    setupMiddleware(app);

    app.use('/regulator/app', express.static(path.join(__dirname, '../../client', 'app')));
    app.use('/regulator/node_modules', express.static(path.join(__dirname, '../..', 'node_modules')));
    app.use('/regulator/assets', express.static(path.join(__dirname, '../../client', 'assets')));
    app.use('/regulator/data', express.static(path.join(__dirname, '../../client', 'data')));

    app.use('/regulator/less/stylesheets/*', function (req, res, next) {
        var url = req.originalUrl;
        var relativePath = url.replace("/regulator/less/stylesheets/", "");
        var lessCSSFile = path.join('../../client', relativePath);
        req.url = lessCSSFile;

        var expressLessObj = expressLess(__dirname, {
            compress: true,
            debug: true
        });
        expressLessObj(req, res, next);
    });

    const fabricProxy = new FabricProxy(config);

    const router = new Router(fabricProxy);

    await router.prepareRoutes();

    app.use('/api', authHandlerFactory(), router.getRouter());

    app.use('/api/*', (req, res) => {
        res.status(404);
        res.send('No endpoint here. Go away');
    });

    app.use('/*', (req, res) => {
        res.sendFile(path.join(__dirname, '../../client/index.html'));
    });

    return app;
}
