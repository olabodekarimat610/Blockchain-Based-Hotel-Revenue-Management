import { describe, it, expect, beforeEach } from 'vitest';

// Mock state
let revenueData = new Map();
let competitorSets = new Map();
let competitorSetProperties = new Map();
let competitorAggregateData = new Map();
let admin = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
let currentTxSender = admin;

// Mock contract functions
const recordRevenueData = (propertyId, date, roomRevenue, otherRevenue, occupancyPercentage, adr) => {
  if (occupancyPercentage > 100) {
    return { error: 1 }; // Invalid occupancy percentage
  }
  
  // Calculate RevPAR
  const revpar = (adr * occupancyPercentage) / 100;
  
  const key = `${propertyId}-${date}`;
  revenueData.set(key, {
    roomRevenue,
    otherRevenue,
    occupancyPercentage,
    adr,
    revpar
  });
  
  return { success: true };
};

const createCompetitorSet = (setId, name) => {
  if (competitorSets.has(setId)) {
    return { error: 2 }; // Competitor set already exists
  }
  
  competitorSets.set(setId, {
    name,
    owner: currentTxSender
  });
  
  return { success: true };
};

const addPropertyToCompetitorSet = (setId, propertyId) => {
  if (!competitorSets.has(setId)) {
    return { error: 3 }; // Competitor set not found
  }
  
  const set = competitorSets.get(setId);
  if (set.owner !== currentTxSender) {
    return { error: 4 }; // Not the owner
  }
  
  const key = `${setId}-${propertyId}`;
  competitorSetProperties.set(key, {
    isMember: true
  });
  
  return { success: true };
};

const updateCompetitorAggregateData = (setId, date, avgOccupancy, avgAdr, avgRevpar, propertyCount) => {
  if (!competitorSets.has(setId)) {
    return { error: 3 }; // Competitor set not found
  }
  
  if (currentTxSender !== admin) {
    return { error: 5 }; // Not authorized
  }
  
  const key = `${setId}-${date}`;
  competitorAggregateData.set(key, {
    avgOccupancy,
    avgAdr,
    avgRevpar,
    propertyCount
  });
  
  return { success: true };
};

const comparePerformance = (propertyId, setId, date) => {
  const propertyKey = `${propertyId}-${date}`;
  const competitorKey = `${setId}-${date}`;
  
  if (!revenueData.has(propertyKey)) {
    return { error: 6 }; // Property data not found
  }
  
  if (!competitorAggregateData.has(competitorKey)) {
    return { error: 7 }; // Competitor data not found
  }
  
  const propertyData = revenueData.get(propertyKey);
  const competitorData = competitorAggregateData.get(competitorKey);
  
  // Calculate indices
  const occupancyIndex = competitorData.avgOccupancy > 0
      ? (propertyData.occupancyPercentage * 100) / competitorData.avgOccupancy
      : 0;
  
  const adrIndex = competitorData.avgAdr > 0
      ? (propertyData.adr * 100) / competitorData.avgAdr
      : 0;
  
  const revparIndex = competitorData.avgRevpar > 0
      ? (propertyData.revpar * 100) / competitorData.avgRevpar
      : 0;
  
  return {
    success: {
      occupancyIndex,
      adrIndex,
      revparIndex
    }
  };
};

// Tests
describe('Performance Tracking Contract', () => {
  beforeEach(() => {
    // Reset state before each test
    revenueData.clear();
    competitorSets.clear();
    competitorSetProperties.clear();
    competitorAggregateData.clear();
    currentTxSender = admin;
  });
  
  it('should record revenue data', () => {
    const result = recordRevenueData('prop1', 20230101, 5000, 1000, 80, 250);
    expect(result.success).toBe(true);
    
    const key = 'prop1-20230101';
    expect(revenueData.has(key)).toBe(true);
    expect(revenueData.get(key).roomRevenue).toBe(5000);
    expect(revenueData.get(key).occupancyPercentage).toBe(80);
    expect(revenueData.get(key).adr).toBe(250);
    expect(revenueData.get(key).revpar).toBe(200); // 250 * 80%
  });
  
  it('should create a competitor set', () => {
    const result = createCompetitorSet('luxury', 'Luxury Hotels');
    expect(result.success).toBe(true);
    
    expect(competitorSets.has('luxury')).toBe(true);
    expect(competitorSets.get('luxury').name).toBe('Luxury Hotels');
  });
  
  it('should add a property to a competitor set', () => {
    createCompetitorSet('luxury', 'Luxury Hotels');
    
    const result = addPropertyToCompetitorSet('luxury', 'prop1');
    expect(result.success).toBe(true);
    
    const key = 'luxury-prop1';
    expect(competitorSetProperties.has(key)).toBe(true);
    expect(competitorSetProperties.get(key).isMember).toBe(true);
  });
  
  it('should update competitor aggregate data', () => {
    createCompetitorSet('luxury', 'Luxury Hotels');
    
    const result = updateCompetitorAggregateData('luxury', 20230101, 75, 230, 172.5, 5);
    expect(result.success).toBe(true);
    
    const key = 'luxury-20230101';
    expect(competitorAggregateData.has(key)).toBe(true);
    expect(competitorAggregateData.get(key).avgOccupancy).toBe(75);
    expect(competitorAggregateData.get(key).avgAdr).toBe(230);
    expect(competitorAggregateData.get(key).avgRevpar).toBe(172.5);
  });
});
