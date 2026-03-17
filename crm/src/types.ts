export interface Customer {
  id: number;
  name: string;
  contact: string;
  email: string;
  status: string;
  health: number;
  mrr: number;
  lastActive: string;
}

export interface Dragon {
  id: number;
  name: string;
  role: string;
  tier: string;
  region: string;
  revenue: string;
  revenueValue: number;
  quota: number;
  winRate: number;
  activeDeals: number;
  status: 'on-fire' | 'stable' | 'warning';
  clients: string[];
}
