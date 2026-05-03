import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/dashboard/pages/dashboard.page').then(m => m.DashboardPage),
  },
  { path: '**', redirectTo: '' },
];
