// QAT Monitoring Widget für Proxmox VE
// Integration in Node-Overview Dashboard

Ext.define('PVE.node.QATStatus', {
    extend: 'Ext.panel.Panel',
    alias: 'widget.pveQATStatus',

    title: 'Intel QAT Status',
    collapsible: true,
    animCollapse: false,
    bodyPadding: 5,
    
    initComponent: function() {
        var me = this;

        me.items = [
            {
                xtype: 'container',
                layout: 'hbox',
                items: [
                    {
                        xtype: 'container',
                        flex: 1,
                        layout: 'vbox',
                        items: [
                            {
                                xtype: 'displayfield',
                                fieldLabel: 'QAT Hardware',
                                itemId: 'qat-available',
                                value: 'Loading...'
                            },
                            {
                                xtype: 'displayfield', 
                                fieldLabel: 'Virtual Functions',
                                itemId: 'virtual-functions',
                                value: '0'
                            },
                            {
                                xtype: 'displayfield',
                                fieldLabel: 'Crypto Engines',
                                itemId: 'crypto-engines', 
                                value: '0'
                            },
                            {
                                xtype: 'displayfield',
                                fieldLabel: 'Total Requests',
                                itemId: 'total-requests',
                                value: '0'
                            }
                        ]
                    },
                    {
                        xtype: 'container',
                        flex: 1,
                        layout: 'vbox',
                        items: [
                            {
                                xtype: 'progressbar',
                                itemId: 'qat-utilization',
                                text: 'QAT Utilization: 0%',
                                value: 0,
                                height: 25,
                                margin: '10 0'
                            },
                            {
                                xtype: 'container',
                                itemId: 'engine-status',
                                html: '<div id="qat-engines"><b>Acceleration Engines:</b><br/>Loading...</div>'
                            }
                        ]
                    }
                ]
            }
        ];

        me.callParent();

        // Start periodic updates
        me.startQATMonitoring();
    },

    startQATMonitoring: function() {
        var me = this;
        
        me.updateQATStatus();
        
        // Update every 5 seconds
        me.monitorTask = Ext.TaskManager.start({
            run: me.updateQATStatus,
            scope: me,
            interval: 5000
        });
    },

    updateQATStatus: function() {
        var me = this;
        
        // API call to get QAT status
        Proxmox.Utils.API2Request({
            url: '/nodes/' + me.nodename + '/qat',
            method: 'GET',
            success: function(response) {
                var data = response.result.data;
                me.updateDisplay(data);
            },
            failure: function() {
                me.updateDisplay({
                    qat_available: false,
                    virtual_functions: 0,
                    crypto_engines: 0,
                    requests_processed: 0,
                    acceleration_engines: []
                });
            }
        });
    },

    updateDisplay: function(data) {
        var me = this;
        
        // Update basic info
        me.down('#qat-available').setValue(
            data.qat_available ? 
            '<span style="color: green;">✓ Available</span>' : 
            '<span style="color: red;">✗ Not Available</span>'
        );
        
        me.down('#virtual-functions').setValue(data.virtual_functions + ' VFs');
        me.down('#crypto-engines').setValue(data.crypto_engines + ' Engines');
        me.down('#total-requests').setValue(Ext.util.Format.number(data.requests_processed, '0,000'));

        // Calculate overall utilization
        var totalUtil = 0;
        if (data.acceleration_engines && data.acceleration_engines.length > 0) {
            var activeEngines = 0;
            data.acceleration_engines.forEach(function(engine) {
                if (engine.requests > 0) {
                    totalUtil += engine.utilization;
                    activeEngines++;
                }
            });
            
            if (activeEngines > 0) {
                totalUtil = totalUtil / activeEngines;
            }
        }
        
        // Update progress bar
        var utilBar = me.down('#qat-utilization');
        utilBar.updateProgress(totalUtil / 100, 'QAT Utilization: ' + Math.round(totalUtil) + '%');
        
        // Color coding
        if (totalUtil > 80) {
            utilBar.addCls('pve-qat-high');
        } else if (totalUtil > 50) {
            utilBar.addCls('pve-qat-medium');
        } else {
            utilBar.addCls('pve-qat-low');
        }

        // Update engine details
        var engineHtml = '<b>Acceleration Engines:</b><br/>';
        if (data.acceleration_engines && data.acceleration_engines.length > 0) {
            data.acceleration_engines.forEach(function(engine) {
                var status = engine.requests > 0 ? 
                    '<span style="color: green;">Active</span>' : 
                    '<span style="color: gray;">Idle</span>';
                    
                engineHtml += 'AE' + engine.id + ': ' + 
                    Ext.util.Format.number(engine.requests, '0,000') + ' req, ' +
                    Math.round(engine.utilization) + '% - ' + status + '<br/>';
            });
        } else {
            engineHtml += '<span style="color: gray;">No engines active</span>';
        }
        
        me.down('#engine-status').update(engineHtml);
    },

    destroy: function() {
        var me = this;
        
        if (me.monitorTask) {
            Ext.TaskManager.stop(me.monitorTask);
        }
        
        me.callParent();
    }
});

// Register the component for use in Proxmox
Ext.define('PVE.node.QATPanel', {
    extend: 'Ext.panel.Panel',
    alias: 'widget.pveNodeQATPanel',
    
    title: 'QAT Hardware Acceleration',
    border: false,
    
    initComponent: function() {
        var me = this;
        
        me.items = [
            {
                xtype: 'pveQATStatus',
                nodename: me.nodename
            }
        ];
        
        me.callParent();
    }
});