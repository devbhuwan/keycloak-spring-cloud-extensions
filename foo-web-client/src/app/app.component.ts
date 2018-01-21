import {Component, OnInit} from '@angular/core';
import {HttpClient} from "@angular/common/http";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {

  foo: any;
  bar: any;
  submit: any;

  constructor(private http: HttpClient) {
  }

  ngOnInit() {
    this.http.get('/foo').subscribe(value => {
      this.foo = value;
    });
    this.http.get('/foo/bar').subscribe(value => {
      this.bar = value;
    });
    this.http.post('/foo/submit', {name: 'Bhuwan'}).subscribe(value => {
      this.submit = value;
    });
  }


}
