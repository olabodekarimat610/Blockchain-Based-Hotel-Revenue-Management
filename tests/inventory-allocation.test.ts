import { describe, it, expect, beforeEach } from 'vitest';

// Mock state
let roomTypes = new Map();
let channels = new Map();
let inventoryAllocation = new Map();
let admin = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
let currentTxSender = admin;

// Mock contract functions
const createRoomType = (propertyId, roomTypeId, name, totalInventory) => {
  const key = `${propertyId}-${roomTypeId}`;
  if (roomTypes.has(key)) {
    return { error: 1 }; // Room type already exists
  }
  
  roomTypes.set(key, {
    name,
    totalInventory,
    owner: currentTxSender
  });
  
  return { success: true };
};

const createChannel = (channelId, name) => {
  if (currentTxSender !== admin) {
    return { error: 2 }; // Not authorized
  }
  
  if (channels.has(channelId)) {
    return { error: 3 }; // Channel already exists
  }
  
  channels.set(channelId, {
    name,
    active: true
  });
  
  return { success: true };
};

const allocateInventory = (propertyId, roomTypeId, channelId, date, amount) => {
  const roomTypeKey = `${propertyId}-${roomTypeId}`;
  if (!roomTypes.has(roomTypeKey)) {
    return { error: 4 }; // Room type not found
  }
  
  const roomType = roomTypes.get(roomTypeKey);
  if (roomType.owner !== currentTxSender) {
    return { error: 2 }; // Not authorized
  }
  
  if (!channels.has(channelId)) {
    return { error: 5 }; // Channel not found
  }
  
  const channel = channels.get(channelId);
  if (!channel.active) {
    return { error: 6 }; // Channel not active
  }
  
  // In a real implementation, we would check total allocation across channels
  // For simplicity, we're just checking against total inventory
  if (amount > roomType.totalInventory) {
    return { error: 7 }; // Exceeds total inventory
  }
  
  const key = `${propertyId}-${roomTypeId}-${channelId}-${date}`;
  inventoryAllocation.set(key, {
    allocated: amount,
    booked: 0
  });
  
  return { success: true };
};

const bookInventory = (propertyId, roomTypeId, channelId, date, amount) => {
  const key = `${propertyId}-${roomTypeId}-${channelId}-${date}`;
  if (!inventoryAllocation.has(key)) {
    return { error: 8 }; // No allocation found
  }
  
  const allocation = inventoryAllocation.get(key);
  const available = allocation.allocated - allocation.booked;
  
  if (available < amount) {
    return { error: 9 }; // Not enough inventory
  }
  
  inventoryAllocation.set(key, {
    allocated: allocation.allocated,
    booked: allocation.booked + amount
  });
  
  return { success: true };
};

const getAvailableInventory = (propertyId, roomTypeId, channelId, date) => {
  const key = `${propertyId}-${roomTypeId}-${channelId}-${date}`;
  if (!inventoryAllocation.has(key)) {
    return { success: 0 }; // No allocation found
  }
  
  const allocation = inventoryAllocation.get(key);
  return { success: allocation.allocated - allocation.booked };
};

// Tests
describe('Inventory Allocation Contract', () => {
  beforeEach(() => {
    // Reset state before each test
    roomTypes.clear();
    channels.clear();
    inventoryAllocation.clear();
    currentTxSender = admin;
  });
  
  it('should create a new room type', () => {
    const result = createRoomType('prop1', 'standard', 'Standard Room', 10);
    expect(result.success).toBe(true);
    
    const key = 'prop1-standard';
    expect(roomTypes.has(key)).toBe(true);
    expect(roomTypes.get(key).name).toBe('Standard Room');
    expect(roomTypes.get(key).totalInventory).toBe(10);
  });
  
  it('should create a new channel', () => {
    const result = createChannel('direct', 'Direct Booking');
    expect(result.success).toBe(true);
    
    expect(channels.has('direct')).toBe(true);
    expect(channels.get('direct').name).toBe('Direct Booking');
    expect(channels.get('direct').active).toBe(true);
  });
  
  it('should allocate inventory to a channel', () => {
    createRoomType('prop1', 'standard', 'Standard Room', 10);
    createChannel('direct', 'Direct Booking');
    
    const result = allocateInventory('prop1', 'standard', 'direct', 20230101, 5);
    expect(result.success).toBe(true);
    
    const key = 'prop1-standard-direct-20230101';
    expect(inventoryAllocation.has(key)).toBe(true);
    expect(inventoryAllocation.get(key).allocated).toBe(5);
    expect(inventoryAllocation.get(key).booked).toBe(0);
  });
  
  it('should book inventory from a channel', () => {
    createRoomType('prop1', 'standard', 'Standard Room', 10);
    createChannel('direct', 'Direct Booking');
    allocateInventory('prop1', 'standard', 'direct', 20230101, 5);
    
    const result = bookInventory('prop1', 'standard', 'direct', 20230101, 2);
    expect(result.success).toBe(true);
    
    const key = 'prop1-standard-direct-20230101';
    expect(inventoryAllocation.get(key).booked).toBe(2);
  });
  
  it('should not book more than available inventory', () => {
    createRoomType('prop1', 'standard', 'Standard Room', 10);
    createChannel('direct', 'Direct Booking');
    allocateInventory('prop1', 'standard', 'direct', 20230101, 5);
    bookInventory('prop1', 'standard', 'direct', 20230101, 3);
    
    const result = bookInventory('prop1', 'standard', 'direct', 20230101, 3);
    expect(result.error).toBe(9); // Not enough inventory
  });
  
  it('should return correct available inventory', () => {
    createRoomType('prop1', 'standard', 'Standard Room', 10);
    createChannel('direct', 'Direct Booking');
    allocateInventory('prop1', 'standard', 'direct', 20230101, 5);
    bookInventory('prop1', 'standard', 'direct', 20230101, 2);
    
    const result = getAvailableInventory('prop1', 'standard', 'direct', 20230101);
    expect(result.success).toBe(3); // 5 allocated - 2 booked
  });
});
