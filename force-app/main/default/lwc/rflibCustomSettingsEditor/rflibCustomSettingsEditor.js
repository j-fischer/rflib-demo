/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import canUserModifyCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.canUserModifyCustomSettings';
import deleteCustomSettingRecord from '@salesforce/apex/rflib_CustomSettingsEditorController.deleteCustomSettingRecord';
import getCustomSettingFields from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingFields';
import getCustomSettingLabel from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingLabel';
import getCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettings';
import saveCustomSetting from '@salesforce/apex/rflib_CustomSettingsEditorController.saveCustomSetting';

export default class RflibCustomSettingsEditor extends LightningElement {
    @api customSettingsApiName;
    @api fieldsToDisplay;

    customSettingsData = [];
    columns = [];
    draftValues = [];
    showModal = false;
    isNewModal = false;
    modalHeader = '';
    selectedType = 'UserType';

    recordId;
    title;
    canModifySettings = false;
    isLoading = false;

    showDeleteConfirmation = false;
    deleteDialogTitle = 'Confirm Deletion';
    deleteDialogMessage = 'Are you sure you want to delete this record?';
    deleteDialogConfirmLabel = 'Delete';
    deleteDialogCancelLabel = 'Cancel';

    fieldInfos = [];
    @track recordValues = {};

    ownerFilter = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true,
            },
        ],
    };

    ownerMatchingInfo = {
        primaryField: { fieldPath: 'Name' },
    };

    connectedCallback() {
        this.isLoading = true;
        this.setTitle();
        this.checkUserPermissions() // checkUserPermissions must complete before the settings are loaded to make sure the correct actions are set.
            .finally(() => this.loadCustomSettings());
    }

    setTitle() {
        getCustomSettingLabel({ customSettingsApiName: this.customSettingsApiName })
            .then((label) => {
                this.title = `${label} Editor`;
            })
            .catch((error) => {
                this.title = 'Custom Settings Editor';
                const errorMessage =
                    'Failed to load custom setting label: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
            });
    }

    checkUserPermissions() {
        return canUserModifyCustomSettings({ customSettingsApiName: this.customSettingsApiName })
            .then((result) => {
                this.canModifySettings = result;
            })
            .catch((error) => {
                const errorMessage = 'Failed to check user permissions: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
            });
    }

    loadCustomSettings() {
        this.isLoading = true;
        getCustomSettings({ customSettingsApiName: this.customSettingsApiName })
            .then((result) => {
                this.customSettingsData = result.map((setting) => {
                    const row = {
                        id: setting.id,
                        setupOwnerId: setting.setupOwnerId,
                        setupOwnerName: setting.setupOwnerName,
                        setupOwnerType: setting.setupOwnerType,
                    };
                    const fieldKeys = Object.keys(setting.fields);
                    fieldKeys.forEach((key) => {
                        row[key] = setting.fields[key];
                    });

                    return row;
                });

                this.columns = this.createColumns(result[0]?.fieldLabels || {});

                this.isLoading = false;
            })
            .catch((error) => {
                const errorMessage = 'Failed to load custom settings: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
                this.isLoading = false;
            });
    }

    createColumns(fieldLabels) {
        const columns = [
            { label: 'Setup Owner Type', fieldName: 'setupOwnerType', type: 'text' },
            { label: 'Setup Owner Name', fieldName: 'setupOwnerName', type: 'text' },
        ];

        if (this.fieldsToDisplay) {
            const fieldNames = this.fieldsToDisplay.split(',').map((field) => field.trim());
            fieldNames.forEach((fieldName) => {
                const fieldLabel = fieldLabels[fieldName] || fieldName;
                columns.push({ label: fieldLabel, fieldName: fieldName, type: 'text' });
            });
        }

        if (this.canModifySettings) {
            columns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: this.getRowActions,
                },
            });
        }

        return columns;
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        actions.push({ label: 'Edit', name: 'edit' });

        if (row.setupOwnerType !== 'Organization') {
            actions.push({ label: 'Delete', name: 'delete' });
        }

        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.recordId = row.id;
        switch (actionName) {
            case 'edit':
                this.handleEditRecord(row);
                break;
            case 'delete':
                this.handleDeleteRecord();
                break;
        }
    }

    handleNewRecord() {
        this.isNewModal = true;
        this.modalHeader = 'New Custom Setting';
        this.recordId = null;
        this.recordValues = {};

        this.loadFieldInfos()
            .then(() => {
                this.showModal = true;
            })
            .catch((error) => {
                const errorMessage = 'Failed to load field information: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
            });
    }

    handleEditRecord(row) {
        this.isNewModal = false;
        this.modalHeader = 'Edit Custom Setting for ' + row.setupOwnerName;
        this.recordValues = { ...row };
        this.setupOwnerId = row.setupOwnerId;
        this.setupOwnerType = row.setupOwnerType;
        this.recordId = row.id;
        this.loadFieldInfos()
            .then(() => {
                this.showModal = true;
            })
            .catch((error) => {
                const errorMessage = 'Failed to load field information: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
            });
    }

    loadFieldInfos() {
        return getCustomSettingFields({ customSettingsApiName: this.customSettingsApiName })
            .then((fields) => {
                this.fieldInfos = fields.map((fieldInfo) => {
                    const dataType = fieldInfo.dataType;
                    const value = this.isNewModal ? fieldInfo.defaultValue : this.recordValues[fieldInfo.apiName];

                    return {
                        ...fieldInfo,
                        isTextField:
                            dataType === 'STRING' || dataType === 'EMAIL' || dataType === 'PHONE' || dataType === 'URL',
                        isNumberField: dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'CURRENCY',
                        isBooleanField: dataType === 'BOOLEAN',
                        value: value,
                    };
                });
            })
            .catch((error) => {
                throw error;
            });
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.fieldName;
        let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        this.recordValues[fieldName] = value;

        const fieldInfo = this.fieldInfos.find((field) => field.apiName === fieldName);
        if (fieldInfo) {
            fieldInfo.value = value;
        }
    }

    handleOwnerIdChanged(event) {
        try {
            let newOwnerId = event.detail.recordId;
            if (this.setupOwnerId !== newOwnerId) {
                this.setupOwnerId = newOwnerId;
            }
        } catch (ex) {
            throw ex;
        }
    }

    closeModal() {
        this.showModal = false;
    }

    handleModalSave() {
        const customSettingRecord = {
            sobjectType: this.customSettingsApiName,
        };

        if (this.recordId) {
            // Existing record - set Id but do not set SetupOwnerId
            customSettingRecord.Id = this.recordId;
        } else {
            // New record - set SetupOwnerId
            customSettingRecord.SetupOwnerId = this.setupOwnerId;
        }

        this.fieldInfos.forEach((fieldInfo) => {
            if (fieldInfo.isCreateable || fieldInfo.isUpdateable) {
                customSettingRecord[fieldInfo.apiName] = fieldInfo.value;
            }
        });

        saveCustomSetting({ customSettingRecord })
            .then(() => {
                this.showToast('Success', 'Record saved successfully.', 'success');
                this.loadCustomSettings();
                this.showModal = false;
            })
            .catch((error) => {
                const errorMessage = 'Failed to save record: ' + (error?.body?.message || 'Unknown reason');
                this.showToast('Error', errorMessage, 'error');
            });
    }

    handleDeleteRecord() {
        this.showDeleteConfirmation = true;
    }

    handleModalAction(event) {
        const status = event.detail.status;
        this.showDeleteConfirmation = false;
        if (status === 'confirm') {
            deleteCustomSettingRecord({
                customSettingsApiName: this.customSettingsApiName,
                recordId: this.recordId,
            })
                .then(() => {
                    this.showToast('Success', 'Record deleted successfully.', 'success');
                    this.loadCustomSettings();
                })
                .catch((error) => {
                    const errorMessage = 'Failed to delete record: ' + (error?.body?.message || 'Unknown reason');
                    this.showToast('Error', errorMessage, 'error');
                });
        }
    }

    handleRefresh() {
        this.loadCustomSettings();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    getPicklistOptions(fieldInfo) {
        return fieldInfo.picklistValues.map((entry) => ({
            label: entry.value,
            value: entry.value,
        }));
    }

    get typeOptions() {
        return [
            { label: 'User', value: 'UserType' },
            { label: 'Profile', value: 'ProfileType' },
        ];
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    get isUserType() {
        return this.selectedType === 'UserType';
    }

    get isProfileType() {
        return this.selectedType === 'ProfileType';
    }
}
