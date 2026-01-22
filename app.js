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

          // キャンバスでのドラッグ
          const canvas = document.getElementById('canvas');
              canvas.addEventListener('mousemove', (e) => this.handleDrag(e));
              canvas.addEventListener('mouseup', () => this.endDrag());
              canvas.addEventListener('mouseleave', () => this.endDrag());
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
