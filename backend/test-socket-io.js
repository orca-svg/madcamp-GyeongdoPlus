#!/usr/bin/env node

/**
 * Socket.IO Connection Test Script
 * 
 * Tests the Socket.IO connection to the backend without running the full Flutter app.
 */

const io = require('socket.io-client');

const BASE_URL = 'http://localhost:3000';
const JWT_TOKEN = 'stub_token_test'; // Test JWT token
const MATCH_ID = 'test-match-123';

console.log('🔌 Socket.IO Connection Test\n');
console.log(`URL: ${BASE_URL}`);
console.log(`JWT: ${JWT_TOKEN}`);
console.log(`Match ID: ${MATCH_ID}\n`);

const socket = io(BASE_URL, {
  transports: ['websocket'],
  auth: {
    token: JWT_TOKEN,
  },
  query: {
    matchId: MATCH_ID,
  },
});

socket.on('connect', () => {
  console.log('✅ Connected to Socket.IO server');
  console.log(`   Socket ID: ${socket.id}\n`);

  // Emit join_room event
  console.log('📤 Emitting join_room event...');
  socket.emit('join_room', { matchId: MATCH_ID });
});

socket.on('joined_room', (data) => {
  console.log('✅ Received joined_room event');
  console.log(`   Data: ${JSON.stringify(data)}\n`);
});

socket.on('player_moved', (data) => {
  console.log('📍 Player moved:');
  console.log(`   ${JSON.stringify(data)}\n`);
});

socket.on('user_arrested', (data) => {
  console.log('🚨 User arrested:');
  console.log(`   ${JSON.stringify(data)}\n`);
});

socket.on('game_over', (data) => {
  console.log('🏁 Game over:');
  console.log(`   ${JSON.stringify(data)}\n`);
});

socket.on('disconnect', (reason) => {
  console.log(`❌ Disconnected: ${reason}`);
});

socket.on('connect_error', (error) => {
  console.error(`❌ Connection error: ${error.message}`);
  process.exit(1);
});

// Keep alive for 30 seconds
setTimeout(() => {
  console.log('\n⏱️  Test timeout - disconnecting...');
  socket.disconnect();
  process.exit(0);
}, 30000);

console.log('⏳ Waiting for events (30s timeout)...\n');
