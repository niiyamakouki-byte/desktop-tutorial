/**
 * 建設DXコックピット v1.0
 * - ノード型工程表（ドラッグ＆ドロップ）
 * - 雨天中止ボタンで後続タスク自動スライド
 * - 着工日と材料納期の逆算アラート
 * - localStorageでデータ永続化
 */

class ConstructionDXApp {
      constructor() {
                this.nodes = new Map();
                this.connections = [];
                this.nextNodeId = 1;
                this.connectionMode = { active: false, fromId: null };
                this.dragState = { active: false, nodeId: null, offsetX: 0, offsetY: 0 };

          this.init();
      }

    init() {
              this.loadData();
              this.bindEvents();
              this.render();
              this.checkAlerts();

          // デモデータがなければ造形モルタルテンプレートを追加
          if (this.nodes.size === 0) {
                        this.addTemplateNodes();
          }
    }

    // === デモ用テンプレート（造形モルタル工事） ===
    addTemplateNodes() {
              const today = new Date();
              const templates = [
                { name: '下地調整', daysFromNow: 7, leadTime: 3, materials: ['下地処理剤', 'プライマー'] },
                { name: 'プライマー塗布', daysFromNow: 10, leadTime: 2, materials: ['専用プライマー'] },
                { name: 'モルタル造形', daysFromNow: 14, leadTime: 7, materials: ['造形モルタル', '骨材', '着色剤'] },
                { name: 'エイジング塗装', daysFromNow: 21, leadTime: 5, materials: ['エイジング塗料', '保護剤'] }
                        ];

          templates.forEach((t, i) => {
                        const date = new Date(today);
                        date.setDate(date.getDate() + t.daysFromNow);

                                        const node = {
                                                          id: this.nextNodeId++,
                                                          name: t.name,
                                                          date: date.toISOString().split('T')[0],
                                                          leadTime: t.leadTime,
                                                          materials: t.materials,
                                                          checklist: { spec: false, drawing: false, order: false, delivery: false },
                                                          position: { x: 50 + (i % 2) * 250, y: 50 + Math.floor(i / 2) * 200 }
                                        };
                        this.nodes.set(node.id, node);
          });

          // 接続を追加
          this.connections = [
            { from: 1, to: 2 },
            { from: 2, to: 3 },
            { from: 3, to: 4 }
                    ];

          this.saveData();
              this.render();
    }

    // === イベントバインディング ===
    bindEvents() {
              // 雨天中止ボタン
          document.getElementById('rainBtn').addEventListener('click', () => this.handleRainDelay());

          // 工程追加ボタン
          document.getElementById('addNodeBtn').addEventListener('click', () => this.openModal());

          // 保存ボタン
          document.getElementById('saveBtn').addEventListener('click', () => {
                        this.saveData();
                        alert('保存しました！');
          });

          // モーダル関連
          document.getElementById('nodeForm').addEventListener('submit', (e) => this.handleFormSubmit(e));
              document.getElementById('closeModalBtn').addEventListener('click', () => this.closeModal());
              document.getElementById('deleteNodeBtn').addEventListener('click', () => this.deleteCurrentNode());

          // 接続キャンセル
          document.getElementById('cancelConnection').addEventListener('click', () => this.cancelConnection());

          // キャンバスでのドラッグ（マウス + タッチ対応）
          const canvas = document.getElementById('canvas');
              canvas.addEventListener('mousemove', (e) => this.handleDrag(e));
              canvas.addEventListener('mouseup', () => this.endDrag());
              canvas.addEventListener('mouseleave', () => this.endDrag());
              
              // タッチイベント対応
              canvas.addEventListener('touchmove', (e) => this.handleDrag(this.touchToMouse(e)), { passive: false });
              canvas.addEventListener('touchend', () => this.endDrag());
              canvas.addEventListener('touchcancel', () => this.endDrag());
    }

    // === 雨天中止機能（キラー機能） ===
    handleRainDelay() {
              const delayDays = parseInt(prompt('何日分遅延させますか？', '1'));
              if (isNaN(delayDays) || delayDays <= 0) return;

          const targetDate = prompt('どの日付以降を遅延させますか？ (YYYY-MM-DD)', new Date().toISOString().split('T')[0]);
              if (!targetDate) return;

          let affected = 0;
              this.nodes.forEach(node => {
                            if (node.date >= targetDate) {
                                              const date = new Date(node.date);
                                              date.setDate(date.getDate() + delayDays);
                                              node.date = date.toISOString().split('T')[0];
                                              affected++;
                            }
              });

          this.saveData();
              this.render();
              this.checkAlerts();

          alert(`☔ ${affected}件の工程を${delayDays}日後ろにスライドしました`);
    }

    // === アラートチェック ===
    checkAlerts() {
              const alerts = [];
              const today = new Date();
              today.setHours(0, 0, 0, 0);

          this.nodes.forEach(node => {
                        const nodeDate = new Date(node.date);
                        const daysUntil = Math.ceil((nodeDate - today) / (1000 * 60 * 60 * 24));

                                         // リードタイム逆算チェック
                                         if (!node.checklist.order && daysUntil <= node.leadTime) {
                                                           const level = daysUntil <= 3 ? 'critical' : 'warning';
                                                           alerts.push({
                                                                                 level,
                                                                                 message: `【${node.name}】材料発注が間に合いません！（残り${daysUntil}日、必要リードタイム${node.leadTime}日）`
                                                           });

                            // ノードにアラートクラスを設定
                            const nodeEl = document.querySelector(`[data-id="${node.id}"]`);
                                                           if (nodeEl) {
                                                                                 nodeEl.classList.remove('alert-critical', 'alert-warning');
                                                                                 nodeEl.classList.add(`alert-${level}`);
                                                           }
                                         }

                                         // チェックリスト未完了警告
                                         const checkCount = Object.values(node.checklist).filter(v => v).length;
                        if (checkCount < 4 && daysUntil <= 7) {
                                          alerts.push({
                                                                level: 'info',
                                                                message: `【${node.name}】準備進捗 ${checkCount}/4（${daysUntil}日後着工）`
                                          });
                        }
          });

          // アラートパネル更新
          const alertList = document.getElementById('alertList');
              alertList.innerHTML = alerts.length > 0 
              ? alerts.map(a => `<li class="${a.level}">${a.message}</li>`).join('')
                            : '<li class="info">現在アラートはありません</li>';
    }

          // === ノード描画 ===
          render() {
                        const container = document.getElementById('nodesContainer');
                        container.innerHTML = '';
                        this.nodes.forEach(node => {
                                          const el = this.createNodeElement(node);
                                          container.appendChild(el);
                        });
                        this.renderConnections();
                        this.checkAlerts();
          }

          createNodeElement(node) {
                        const el = document.createElement('div');
                        el.className = 'node';
                        el.dataset.id = node.id;
                        el.style.left = node.position.x + 'px';
                        el.style.top = node.position.y + 'px';
                        const checkCount = Object.values(node.checklist).filter(v => v).length;
                        const progress = (checkCount / 4) * 100;
                        el.innerHTML = '<div class="node-header"><span class="node-title">' + node.name + '</span><span class="node-date">' + node.date + '</span></div><div class="node-progress"><div class="node-progress-bar" style="width:' + progress + '%"></div></div><div class="node-materials">📦 ' + node.materials.join(', ') + '</div><div class="node-actions"><button class="btn-connect" data-action="connect">🔗 接続</button><button class="btn-edit" data-action="edit">✏️ 編集</button></div>';
                        
                        // マウスイベント
                        el.addEventListener('mousedown', (e) => { if (e.target.tagName !== 'BUTTON') this.startDrag(e, node.id); });
                        
                        // タッチイベント
                        el.addEventListener('touchstart', (e) => { 
                            if (e.target.tagName !== 'BUTTON') {
                                this.startDrag(this.touchToMouse(e), node.id);
                            }
                        }, { passive: false });
                        
                        el.querySelector('[data-action="connect"]').addEventListener('click', () => this.startConnection(node.id));
                        el.querySelector('[data-action="edit"]').addEventListener('click', () => this.openModal(node.id));
                        el.addEventListener('click', () => { if (this.connectionMode.active && this.connectionMode.fromId !== node.id) this.completeConnection(node.id); });
                        return el;
          }
          
          // タッチイベントをマウスイベントに変換
          touchToMouse(e) {
                        if (e.touches && e.touches.length > 0) {
                                          e.preventDefault(); // デフォルトのタッチスクロールを防止（ドラッグ中のみ）
                                          const touch = e.touches[0];
                                          return { clientX: touch.clientX, clientY: touch.clientY, target: e.target };
                        }
                        return e;
          }

          startDrag(e, nodeId) {
                        const rect = e.target.closest('.node').getBoundingClientRect();
                        const canvas = document.getElementById('canvas');
                        const canvasRect = canvas.getBoundingClientRect();
                        this.dragState = { active: true, nodeId, offsetX: e.clientX - rect.left, offsetY: e.clientY - rect.top, canvasLeft: canvasRect.left + canvas.scrollLeft, canvasTop: canvasRect.top + canvas.scrollTop };
          }

          handleDrag(e) {
                        if (!this.dragState.active) return;
                        const canvas = document.getElementById('canvas');
                        const node = this.nodes.get(this.dragState.nodeId);
                        node.position.x = Math.max(0, e.clientX - this.dragState.canvasLeft - this.dragState.offsetX + canvas.scrollLeft);
                        node.position.y = Math.max(0, e.clientY - this.dragState.canvasTop - this.dragState.offsetY + canvas.scrollTop);
                        const el = document.querySelector('[data-id="' + this.dragState.nodeId + '"]');
                        el.style.left = node.position.x + 'px';
                        el.style.top = node.position.y + 'px';
                        this.renderConnections();
          }

          endDrag() { if (this.dragState.active) this.saveData(); this.dragState.active = false; }

          renderConnections() {
                        const svg = document.getElementById('connectionsSvg');
                        svg.innerHTML = '';
                        this.connections.forEach(conn => {
                                          const fromNode = this.nodes.get(conn.from);
                                          const toNode = this.nodes.get(conn.to);
                                          if (!fromNode || !toNode) return;
                                          const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
                                          const fromX = fromNode.position.x + 100, fromY = fromNode.position.y + 80;
                                          const toX = toNode.position.x + 100, toY = toNode.position.y;
                                          const midY = (fromY + toY) / 2;
                                          path.setAttribute('d', 'M ' + fromX + ' ' + fromY + ' C ' + fromX + ' ' + midY + ', ' + toX + ' ' + midY + ', ' + toX + ' ' + toY);
                                          svg.appendChild(path);
                        });
          }

          startConnection(fromId) { this.connectionMode = { active: true, fromId }; document.getElementById('connectionMode').classList.remove('hidden'); document.querySelector('[data-id="' + fromId + '"]').classList.add('selected'); }
          completeConnection(toId) { if (!this.connections.some(c => c.from === this.connectionMode.fromId && c.to === toId)) { this.connections.push({ from: this.connectionMode.fromId, to: toId }); this.renderConnections(); this.saveData(); } this.cancelConnection(); }
          cancelConnection() { if (this.connectionMode.fromId) { const el = document.querySelector('[data-id="' + this.connectionMode.fromId + '"]'); if (el) el.classList.remove('selected'); } this.connectionMode = { active: false, fromId: null }; document.getElementById('connectionMode').classList.add('hidden'); }

          openModal(nodeId = null) {
                        this.currentEditId = nodeId;
                        const modal = document.getElementById('nodeModal');
                        const deleteBtn = document.getElementById('deleteNodeBtn');
                        if (nodeId) {
                                          const node = this.nodes.get(nodeId);
                                          document.getElementById('modalTitle').textContent = '工程編集';
                                          document.getElementById('nodeName').value = node.name;
                                          document.getElementById('nodeDate').value = node.date;
                                          document.getElementById('nodeLeadTime').value = node.leadTime;
                                          document.getElementById('nodeMaterials').value = node.materials.join('\n');
                                          document.getElementById('checkSpec').checked = node.checklist.spec;
                                          document.getElementById('checkDrawing').checked = node.checklist.drawing;
                                          document.getElementById('checkOrder').checked = node.checklist.order;
                                          document.getElementById('checkDelivery').checked = node.checklist.delivery;
                                          deleteBtn.style.display = 'block';
                        } else {
                                          document.getElementById('modalTitle').textContent = '新規工程追加';
                                          document.getElementById('nodeForm').reset();
                                          document.getElementById('nodeDate').value = new Date().toISOString().split('T')[0];
                                          deleteBtn.style.display = 'none';
                        }
                        modal.classList.remove('hidden');
          }

          closeModal() { document.getElementById('nodeModal').classList.add('hidden'); this.currentEditId = null; }

          handleFormSubmit(e) {
                        e.preventDefault();
                        const nodeData = { name: document.getElementById('nodeName').value, date: document.getElementById('nodeDate').value, leadTime: parseInt(document.getElementById('nodeLeadTime').value) || 7, materials: document.getElementById('nodeMaterials').value.split('\n').filter(m => m.trim()), checklist: { spec: document.getElementById('checkSpec').checked, drawing: document.getElementById('checkDrawing').checked, order: document.getElementById('checkOrder').checked, delivery: document.getElementById('checkDelivery').checked } };
                        if (this.currentEditId) { Object.assign(this.nodes.get(this.currentEditId), nodeData); }
                        else { const newNode = { id: this.nextNodeId++, ...nodeData, position: { x: 100 + Math.random() * 200, y: 100 + Math.random() * 200 } }; this.nodes.set(newNode.id, newNode); }
                        this.saveData(); this.render(); this.closeModal();
          }

          deleteCurrentNode() {
                        if (!this.currentEditId || !confirm('この工程を削除しますか？')) return;
                        this.nodes.delete(this.currentEditId);
                        this.connections = this.connections.filter(c => c.from !== this.currentEditId && c.to !== this.currentEditId);
                        this.saveData(); this.render(); this.closeModal();
          }

          saveData() { localStorage.setItem('constructionDX_data', JSON.stringify({ nodes: Array.from(this.nodes.entries()), connections: this.connections, nextNodeId: this.nextNodeId })); }
          loadData() { const saved = localStorage.getItem('constructionDX_data'); if (saved) { const data = JSON.parse(saved); this.nodes = new Map(data.nodes); this.connections = data.connections || []; this.nextNodeId = data.nextNodeId || 1; } }
}

document.addEventListener('DOMContentLoaded', () => { window.app = new ConstructionDXApp(); });
