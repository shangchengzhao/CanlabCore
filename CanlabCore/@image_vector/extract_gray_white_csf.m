function [values, components, full_data_objects] = extract_gray_white_csf(obj)
% Extracts mean values (values) and top 5 component scores (components)
% from each of gray, white, and CSF masks.
%
% - Images must be in standard MNI space for this to apply.
% - Uses canonical masks in CANlab tools:'gray_matter_mask.img' 'canonical_white_matter.img' 'canonical_ventricles.img' 
%
% This currently uses the images
%       'gray_matter_mask.img' 'canonical_white_matter.img' 'canonical_ventricles.img'
%       These images are based on the SPM8 a priori tissue probability
%       maps, but they have been cleaned up and made symmetrical and/or eroded
%       so that the white and CSF compartments are unlikely to contain very
%       much gray matter.  The gray compartment is currently more
%       inclusive. The potential value of this is that signal in the CSF/white
%       compartments may be removed from images prior to/during analysis
%
% :Usage:
% ::
%
%     [values, components] = extract_gray_white_csf(obj)
%
% :Inputs:
%
%   **obj:**
%        an image_vector (e.g., fmri_data) object
%
% : Outputs:
% 
%   **values:**
%        mean gray matter, white, CSF
%
%   **components:**
%        first 5 components from each tissue class, observation x 5
%
%   **full_data_objects:**
%        Masked data objects for {gray white CSF}
%
% ..
%    Tor Wager, July 21, 2015
% ..

% Programmers' notes:
% Jan 2017:  Issue with vector lengths if obj has removed images, fixed (Tor)

numcomps = 5;

masks = {'gray_matter_mask.img' 'canonical_white_matter.img' 'canonical_ventricles.img'};

obj = remove_empty(obj);  % return only non-empty values
nimgs = size(obj.dat, 2); % - sum(obj.removed_images);

values = NaN * zeros(nimgs, length(masks));
components = cell(1, length(masks));
full_data_objects = [];

for i = 1:length(masks)
    
    maskname = which(masks{i});
    
    if isempty(maskname)
       fprintf('Image %s cannot be found on path.\n', masks{i});
       error('Exiting');
    else
        fprintf('Extracting from %s.\n', masks{i});
    end
    
    masked_obj = apply_mask(obj, maskname);

    % get all values, if requested
    if nargout > 2
        
        full_data_objects{i} = remove_empty(masked_obj);

    end
           
    % get means
    masked_obj.dat(masked_obj.dat == 0) = NaN;
    
    myvalues = nanmean(masked_obj.dat, 1)';
    
    % may need to insert omitted - no, return in reduced space
%     if length(masked_obj.removed_images) > 1
%         myvalues = naninsert(masked_obj.removed_images, myvalues);
%     end
    
    values(:, i) = myvalues;
    

    % get components
    if nargout > 1
        
        % NaNs will mess this up - remove voxel-wise
        [wasnan, dataforpca] = nanremove(masked_obj.dat);
        if any(wasnan), fprintf('Removing %3.0f voxels with one or more NaNs\n', sum(wasnan)); end
        
        [~, components{i}] = pca(dataforpca', 'Economy', true, 'NumComponents', numcomps);
        
        % may need to insert omitted
%         if length(masked_obj.removed_images) > 1
%             components{i} = naninsert(masked_obj.removed_images, components{i});
%         end
        
    end
    
    
    
end % end masks


end % function

