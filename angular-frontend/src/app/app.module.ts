import { NgModule } from '@angular/core';
import { BrowserModule, provideClientHydration } from '@angular/platform-browser';
import {AngularFireModule} from "@angular/fire/compat";
import {AngularFireAuthModule} from "@angular/fire/compat/auth";

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { environment } from '../environments/environment';
import {FormsModule, ReactiveFormsModule} from "@angular/forms";
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
import {NgOptimizedImage} from "@angular/common";
import { NavbarComponent } from './navbar/navbar.component';
import { AusleiheComponent } from './ausleihe/ausleihe.component';
import { EkeyListComponent } from './ekey-list/ekey-list.component';
import { CreateEkeyModalComponent } from './ekey-list/create-ekey-modal/create-ekey-modal.component';
import { HttpClientModule } from '@angular/common/http';
import { RueckgabeComponent } from './rueckgabe/rueckgabe.component';
import { RueckmeldungComponent } from './rueckmeldung/rueckmeldung.component';
import { AuthComponent } from './auth/auth.component';
import {LoadingSpinnerComponent} from "../assets/loading-spinner/loading-spinner.component";
import { EditEkeyModalComponent } from './ekey-list/edit-ekey-modal/edit-ekey-modal.component';
import { EntsperrEkeyModalComponent } from './ekey-list/entsperr-ekey-modal/entsperr-ekey-modal.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { ToastrModule } from 'ngx-toastr';

import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { AuthInterceptor } from './AutInterceptor';
@NgModule({
  declarations: [
    AppComponent,
    NavbarComponent,
    AusleiheComponent,
    DashboardComponent,
    EkeyListComponent,
    CreateEkeyModalComponent,
    RueckgabeComponent,
    RueckmeldungComponent,
    AuthComponent,
    LoadingSpinnerComponent,
    EditEkeyModalComponent,
    EntsperrEkeyModalComponent,
  ],
    imports: [
        BrowserModule,
        AppRoutingModule,
        AngularFireModule.initializeApp(environment.firebase),
        AngularFireAuthModule,
        FormsModule,
        NgbModule,
        NgOptimizedImage,
        HttpClientModule,
        ReactiveFormsModule,
      BrowserAnimationsModule, // required animations module
      ToastrModule.forRoot(), // ToastrModule added
    ],
  providers: [
    provideClientHydration(),
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },

  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
